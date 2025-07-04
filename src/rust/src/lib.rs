//! This crate provides a high-performance engine for serializing and deserializing
//! R objects to and from the Concise Binary Object Representation (CBOR) format,
//! as defined in RFC 8949. By leveraging Rust's performance and safety with
//! `serde` and `ciborium`, this package provides a fast alternative to other
//! serialization formats in R.

use extendr_api::prelude::*;
use ciborium::{from_reader, into_writer};
use serde::{Serialize, Deserialize};
use indexmap::IndexMap;

// A dedicated, tagged enum for special R values that could all be
// serialized to `null` or look like generic objects, causing ambiguity.
// This makes them distinct during serialization.
#[derive(Serialize, Deserialize, Debug, Clone)]
#[serde(tag = "$R_TYPE")]
pub enum SpecialTaggedValue {
    Null,
    NA,
    EmptyList,
    EmptyLogicalVec,
    EmptyIntegerVec,
    EmptyFloatVec,
    EmptyStringVec,
}

/// Represents any R value that can be encoded or decoded.
#[derive(Serialize, Deserialize, Debug, Clone)]
#[serde(untagged)]
pub enum RValue {
    // Prioritize the Special variant during deserialization.
    // `serde` tries to match variants in order for untagged enums. Since our
    // `SpecialTaggedValue` is serialized as a map (e.g., `{"$R_TYPE": "NA"}`),
    // it can be confused with the generic `Object` variant. By putting `Special`
    // first, we instruct `serde` to check for the `$R_TYPE` tag before trying
    // other variants, which resolves the ambiguity.
    Special(SpecialTaggedValue),
    Integer(i32),
    Float(f64),
    Bool(bool),
    String(String),
    Array(Vec<RValue>),
    Object(IndexMap<String, RValue>),
}

impl RValue {
    /// Converts an R object (`Robj`) into an `RValue`.
    pub fn from_robj(robj: &Robj) -> Result<Self> {
        if robj.is_null() {
            return Ok(RValue::Special(SpecialTaggedValue::Null));
        }
        if robj.is_logical() {
            if robj.len() == 0 { return Ok(RValue::Special(SpecialTaggedValue::EmptyLogicalVec)); }
            let v = robj.as_logical_vector().unwrap();
            let vals: Vec<_> = v.iter().map(|x| {
                if x.is_na() { RValue::Special(SpecialTaggedValue::NA) } else { RValue::Bool(x.to_bool()) }
            }).collect();
            // Return single values as-is, not as an array of one.
            if vals.len() == 1 { Ok(vals[0].clone()) } else { Ok(RValue::Array(vals)) }
        } else if robj.is_integer() {
            if robj.len() == 0 { return Ok(RValue::Special(SpecialTaggedValue::EmptyIntegerVec)); }
            let v = robj.as_integer_vector().unwrap();
            let vals: Vec<_> = v.iter().map(|x| {
                if x.is_na() { RValue::Special(SpecialTaggedValue::NA) } else { RValue::Integer(*x) }
            }).collect();
            if vals.len() == 1 { Ok(vals[0].clone()) } else { Ok(RValue::Array(vals)) }
        } else if robj.is_real() {
            if robj.len() == 0 { return Ok(RValue::Special(SpecialTaggedValue::EmptyFloatVec)); }
            let v = robj.as_real_vector().unwrap();
            let vals: Vec<_> = v.iter().map(|x| {
                if x.is_na() {
                    RValue::Special(SpecialTaggedValue::NA)
                } else {
                    let f = *x;
                    // Explicitly handle NaN and Inf...their bit patterns can be quite tricky
                    if f.is_nan() { RValue::Float(f64::NAN) }
                    else if f.is_infinite() { RValue::Float(f) } // Handles Inf and -Inf
                    else { RValue::Float(f) }
                }
            }).collect();
            if vals.len() == 1 { Ok(vals[0].clone()) } else { Ok(RValue::Array(vals)) }
        } else if robj.is_string() {
            if robj.len() == 0 { return Ok(RValue::Special(SpecialTaggedValue::EmptyStringVec)); }
            let v = robj.as_str_vector().unwrap();
            let vals: Vec<_> = v.iter().map(|x| {
                if x.is_na() { RValue::Special(SpecialTaggedValue::NA) } else { RValue::String(x.to_string()) }
            }).collect();
            if vals.len() == 1 { Ok(vals[0].clone()) } else { Ok(RValue::Array(vals)) }
        } else if robj.is_list() {
            if robj.len() == 0 { return Ok(RValue::Special(SpecialTaggedValue::EmptyList)); }
            let list = robj.as_list().unwrap();
            if list.has_names() {
                let mut map = IndexMap::new();
                for (name, val) in list.iter() {
                    map.insert(name.to_string(), RValue::from_robj(&val)?);
                }
                Ok(RValue::Object(map))
            } else {
                let arr = list.iter().map(|(_, val)| RValue::from_robj(&val)).collect::<Result<Vec<_>>>()?;
                Ok(RValue::Array(arr))
            }
        } else {
            Err(Error::Other(format!("Unsupported R type for CBOR conversion: {:?}", robj.rtype())))
        }
    }

    /// Converts an `RValue` back into an R object (`Robj`).
    pub fn to_robj(self) -> Robj {
        match self {
            RValue::Integer(i) => Robj::from(i),
            RValue::Float(f) => Robj::from(f),
            RValue::Bool(b) => Robj::from(b),
            RValue::String(s) => Robj::from(s),
            RValue::Special(special) => match special {
                SpecialTaggedValue::Null => Robj::from(()), // Converts to R NULL
                SpecialTaggedValue::NA => Robj::from(Rbool::na()), // Default to logical NA for standalone
                SpecialTaggedValue::EmptyList => List::new(0).into(),
                SpecialTaggedValue::EmptyLogicalVec => Logicals::new(0).into(),
                SpecialTaggedValue::EmptyIntegerVec => Integers::new(0).into(),
                SpecialTaggedValue::EmptyFloatVec => Doubles::new(0).into(),
                SpecialTaggedValue::EmptyStringVec => Strings::new(0).into(),
            },
            RValue::Array(arr) => {
                // When converting an array back to an R object, we must check if it's a
                // homogeneous array that can become an atomic vector or if it must be a generic list.
                
                // Check for logical vectors (Bool or NA)
                if arr.iter().all(|x| matches!(x, RValue::Bool(_) | RValue::Special(SpecialTaggedValue::NA))) {
                    let v: Vec<_> = arr.into_iter().map(|x| match x { RValue::Bool(b) => Some(b), _ => None }).collect();
                    return Robj::from(v);
                }
                // Check for integer vectors (Integer or NA)
                if arr.iter().all(|x| matches!(x, RValue::Integer(_) | RValue::Special(SpecialTaggedValue::NA))) {
                    let v: Vec<_> = arr.into_iter().map(|x| match x { RValue::Integer(i) => Some(i), _ => None }).collect();
                    return Robj::from(v);
                }
                // Check for numeric vectors (Float or NA)
                if arr.iter().all(|x| matches!(x, RValue::Float(_) | RValue::Special(SpecialTaggedValue::NA))) {
                    let v: Vec<_> = arr.into_iter().map(|x| match x { RValue::Float(f) => Some(f), _ => None }).collect();
                    return Robj::from(v);
                }
                // Check for character vectors (String or NA)
                if arr.iter().all(|x| matches!(x, RValue::String(_) | RValue::Special(SpecialTaggedValue::NA))) {
                    let v: Vec<_> = arr.into_iter().map(|x| match x { RValue::String(s) => Some(s), _ => None }).collect();
                    return Robj::from(v);
                }
                
                // Fallback for heterogeneous arrays: create a generic list.
                let mut list = List::new(arr.len());
                for (i, val) in arr.into_iter().enumerate() {
                    list.set_elt(i, val.to_robj()).unwrap();
                }
                list.into()
            }
            RValue::Object(map) => {
                let mut list = List::new(map.len());
                let names: Vec<&str> = map.keys().map(|s| s.as_str()).collect();
                list.set_names(&names).unwrap();
                for (i, val) in map.into_values().enumerate() {
                    list.set_elt(i, val.to_robj()).unwrap();
                }
                list.into()
            }
        }
    }
}

/// Encode an R object into a CBOR byte vector
///
/// This function takes an R object and serializes it into a `raw` vector
/// representing the object in CBOR format. It supports most common R data
/// types, including atomic vectors, lists, and `NULL`.
///
/// @param x The R object to encode.
/// @return A `raw` vector containing the CBOR representation of the object.
/// @examples
/// # Encode a simple integer
/// raw_bytes <- encode(123L)
///
/// # Encode a named list
/// my_list <- list(a = 1, b = "hello", c = c(TRUE, FALSE, NA))
/// encoded_list <- encode(my_list)
///
/// # The output is a raw vector
/// class(encoded_list)
///
/// @export
#[extendr]
fn encode(x: Robj) -> Result<Raw> {
    let r_val = RValue::from_robj(&x)?;
    let mut bytes = Vec::new();
    into_writer(&r_val, &mut bytes).map_err(|e| Error::Other(e.to_string()))?;
    Ok(Raw::from_bytes(&bytes))
}

/// Decode a CBOR byte vector into an R object
///
/// This function takes a `raw` vector of bytes and deserializes it back
/// into an R object, assuming the bytes are in valid CBOR format.
///
/// @param bytes A `raw` vector of CBOR bytes.
/// @return The decoded R object.
/// @examples
/// # Create a CBOR byte string (e.g., from an external source or `encode`)
/// encoded_obj <- encode(list(id = 42, user = "test"))
///
/// # Decode it back to an R object
/// decoded_obj <- decode(encoded_obj)
///
/// # Verify the structure
/// str(decoded_obj)
///
/// @export
#[extendr]
fn decode(bytes: Raw) -> Result<Robj> {
    let r_val: RValue = from_reader(bytes.as_slice()).map_err(|e| Error::Other(e.to_string()))?;
    Ok(r_val.to_robj())
}

// Macro to generate exports
extendr_module! {
    mod RCBOR;
    fn encode;
    fn decode;
}

# RCBOR Development Roadmap

This document outlines the planned features and improvements for the `{RCBOR}` package. The core `encode()` and `decode()` engine is stable and performant, but the following additions will make the package more complete.
Contributions and suggestions are welcome!

## Highest Priority: Quality of Life & Convenience

These features will make the package much easier to use in common, everyday workflows.

- [ ] **File I/O Wrappers:**
  
  - [ ] Implement `write_cbor(x, path)` to encode an R object directly to a file.
    
  - [ ] Implement `read_cbor(path)` to decode a CBOR file directly into an R object.
    

## Medium Priority: Enhanced R Type Support

This involves extending the Rust engine to intelligently handle R-specific object attributes to ensure perfect serialization and deserialization of more complex types.

- [ ] **Full `data.frame` Support:**
  
  - [ ] Add logic to detect if a CBOR map was originally a `data.frame`.
    
  - [ ] Ensure `row.names` are preserved correctly.
    
  - [ ] Reconstruct the `data.frame` class and attributes upon decoding.
    
- [ ] **Preserve `factor` Types:**
  
  - [ ] Create a custom serialization strategy for factors that encodes both the integer vector and the character vector of levels.
    
  - [ ] Rebuild the `factor` object with its levels upon decoding.
    
- [ ] **Date/Time Support using CBOR Tags:**
  
  - [ ] Implement serialization for R's `Date` and `POSIXct` objects using the standard CBOR Tag 0 (datetime string) or Tag 1 (epoch time).
    
  - [ ] Implement deserialization for standard datetime tags back into the correct R types.
    

## Low Priority: Advanced Tools & Integrations

These are more advanced features for debugging and for users in specific domains.

- [ ] **Diagnostic Tools:**
  
  - [ ] Create a `cbor_diag(bytes)` function that takes a raw vector and prints a human-readable, indented summary of the CBOR data structure without fully decoding it to an R object. This would be invaluable for debugging interoperability issues.
- [ ] **Explore S4 Object Serialization:**
  
  - [ ] Research a potential strategy for serializing S4 objects, which are common in bioinformatics packages (e.g., Bioconductor). This is a complex task but would make the package extremely valuable for that community.

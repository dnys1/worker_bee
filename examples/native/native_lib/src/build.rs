use std::collections::HashMap;

fn main() {
    let crate_dir = std::env::var("CARGO_MANIFEST_DIR").unwrap();
    let config = cbindgen::Config {
        language: cbindgen::Language::C,
        documentation_style: cbindgen::DocumentationStyle::C99,
        line_length: 150,
        style: cbindgen::Style::Both,
        enumeration: cbindgen::EnumConfig {
            prefix_with_name: true,
            ..Default::default()
        },
        no_includes: true,
        sys_includes: vec![String::from("stdint.h")],
        defines: HashMap::from([(String::from("feature = dart-ffi"), String::from("DART"))]),
        parse: cbindgen::ParseConfig {
            parse_deps: true,
            include: Some(vec![String::from("allo-isolate")]),
            extra_bindings: vec![String::from("allo-isolate")],
            ..Default::default()
        },
        ..Default::default()
    };
    cbindgen::Builder::new()
        .with_crate(crate_dir)
        .with_config(config)
        .generate()
        .expect("Unable to generate bindings")
        .write_to_file("binding.h");
}

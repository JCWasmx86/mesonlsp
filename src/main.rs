use std::path::PathBuf;

use clap::Parser;
use tree_sitter::Parser as TSParser;

mod ast;
mod wrap;

#[derive(Parser, Debug)]
struct Cli {
    #[clap(long, action)]
    pub lsp: bool,
    #[clap(long, action)]
    pub wrap: bool,
    #[clap(long, action)]
    pub stdio: bool,
    #[clap(long, action)]
    pub test: bool,
    #[clap(long, action)]
    pub wrap_output: Option<String>,
    #[clap(long, action)]
    pub package_files: Option<String>,
    #[clap(short, long, value_parser, num_args = 1.., value_delimiter = ' ')]
    pub files: Vec<PathBuf>,
}

#[warn(non_snake_case)]
fn main() {
    let cli = Cli::parse();
    let mut parser = TSParser::new();
    parser
        .set_language(tree_sitter_meson::language())
        .expect("Error loading Meson grammar");
    let source_code = "project('cccc', language: 'c')\n";
    let tree = parser.parse(source_code, None).unwrap();
    let root_node = tree.root_node();
    println!("{:#?} {:#?}", root_node.to_sexp(), cli);

    if cli.lsp {
        unimplemented!("LSP is unimplemented!");
    } else if cli.wrap {
        unimplemented!("Wrap is unimplemented");
    } else if cli.test {
        unimplemented!("Test is unimplemented");
    } else {
    }
}

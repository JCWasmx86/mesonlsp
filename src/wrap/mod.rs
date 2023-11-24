use std::path::PathBuf;


pub enum Method {
    Meson,
    CMake,
    Cargo
}
pub trait Wrap {
    fn name(self) -> String;
    fn patch_url(self) -> Option<String>;
    fn patch_fallback_url(self) -> Option<String>;
    fn patch_filename(self) -> Option<String>;
    fn patch_hash(self) -> Option<String>;
    fn patch_directory(self) -> Option<String>;
    fn diff_files(self) -> Vec<PathBuf>;
    fn method(self) -> Method;
    fn install(self);
    fn update(self);
}

pub struct CommonWrap {
    pub directory: PathBuf,
    pub wrap_file: PathBuf,
    pub name: String,
    pub patch_url: Option<String>,
    pub patch_fallback_url: Option<String>,
    pub patch_filename: Option<String>,
    pub patch_hash: Option<String>,
    pub patch_directory: Option<PathBuf>,
    pub diff_files: Vec<PathBuf>,
    pub method: Method,
}

pub struct CommonVcsWrap {
    pub common_wrap: CommonWrap,
    pub url: String,
    pub revision: String
}

pub struct FileWrap {
    pub common_wrap: CommonWrap,
    pub metadata: String,
    pub source_url: String,
    pub source_fallback_url: String,
    pub source_filename: String,
    pub source_hash: String,
    pub lead_directory_missing: bool
}


pub struct GitWrap {
    pub common_vcs_wrap: CommonVcsWrap,
    pub depth: Option<u64>,
    pub push_url: Option<String>,
    pub clone_recursive: bool
}

pub struct SvnWrap {
    pub common_vcs_wrap: CommonVcsWrap,
}

pub struct HgWrap {
    pub common_vcs_wrap: CommonVcsWrap,
}

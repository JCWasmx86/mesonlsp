use std::collections::HashMap;

#[derive(PartialEq)]
enum Callable {
    Function(Function),
    Method(Method),
}

#[derive(Debug)]
pub struct Type {
    name: String,
}

impl PartialEq for Type {
    fn eq(&self, other: &Self) -> bool {
        return self.name == other.name;
    }
}

#[derive(Debug, PartialEq)]
enum Argument {
    Kwarg(Kwarg),
    PositionalArgument(PositionalArgument),
}

#[derive(Debug)]
pub struct Kwarg {
    name: String,
    opt: bool,
    types: Vec<Type>,
}

impl PartialEq for Kwarg {
    fn eq(&self, other: &Self) -> bool {
        return self.name == other.name;
    }
}

#[derive(Debug)]
pub struct PositionalArgument {
    name: String,
    opt: bool,
    varargs: bool,
    types: Vec<Type>,
}

impl PartialEq for PositionalArgument {
    fn eq(&self, other: &Self) -> bool {
        return self.name == other.name;
    }
}

#[derive(Debug)]
pub struct Function {
    name: String,
    return_types: Vec<Type>,
    args: Vec<Argument>,
    kwargs: HashMap<String, Kwarg>,
    min_pos_args_: i32,
    max_pos_args_: i32,
    required_kwargs_: Vec<String>,
}

impl PartialEq for Function {
    fn eq(&self, other: &Self) -> bool {
        self.name == other.name
            && self.return_types == other.return_types
            && self.args == other.args
            && self.min_pos_args_ == other.min_pos_args_
            && self.max_pos_args_ == other.max_pos_args_
            && self.required_kwargs_ == other.required_kwargs_
    }
}

#[derive(Debug)]
pub struct Method {
    parent: Type,
    function: Function,
}

impl PartialEq for Method {
    fn eq(&self, other: &Self) -> bool {
        self.parent == other.parent && self.function == other.function
    }
}

#[derive(Debug)]
pub enum AssignmentOperator {}

#[derive(Debug)]
pub enum BinaryOperator {}

#[derive(Debug)]
pub enum NodeData<'a> {
    ArgumentList(Vec<Node<'a>>),
    ArrayLiteral(Vec<Node<'a>>),
    AssignmentStatement(Box<Node<'a>>, AssignmentOperator, Box<Node<'a>>),
    BinaryExpression(Box<Node<'a>>, BinaryOperator, Box<Node<'a>>),
    BooleanLiteral(bool),
    BreakNode(),
    BuildDefinition(Vec<Node<'a>>),
    ConditionalExpression(Vec<Node<'a>>, Vec<Node<'a>>, Vec<Node<'a>>),
    ContinueNode(),
    DictionaryLiteral(Vec<Node<'a>>),
}

#[derive(Debug)]
pub struct Location {
    pub file: String,
    pub start_line: u64,
    pub end_line: u64,
    pub start_column: u64,
    pub end_column: u64,
}

#[derive(Debug)]
pub struct Node<'a> {
    pub location: Location,
    pub parent: Option<Box<Node<'a>>>,
    pub data: NodeData<'a>,
    pub types: Vec<&'a Type>,
}

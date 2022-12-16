from pathlib import Path
from luadoc.parser import DocParser, DocOptions
from contextlib import contextmanager
from luadoc.model import (
    LuaClass,
    LuaFunction,
    LuaModule,
    LuaParam,
    LuaReturn,
    LuaType,
    LuaTypeAny,
    LuaTypeBoolean,
    LuaTypeCallable,
    LuaTypeCustom,
    LuaTypeFunction,
    LuaTypeNumber,
    LuaTypeString,
)
from snakemd import (
    Document as BaseDocument,
    InlineText,
    Header,
    Element,
    Table,
    Paragraph,
)
from re import sub, escape


class RawElement(Element):
    def __init__(self, text):
        self._text = text

    def render(self):
        return self._text


def get_access_string(property):
    if property["get"] and not property["set"]:
        return "read-only"
    if property["get"] and property["set"]:
        return "read/write"
    return "write-only"

def get_methods(class_: LuaClass):
    return list([it for it in class_.methods if not it.name.startswith("properties") and it.visibility == "public" and not it.name == "init"])

def get_constructor(class_: LuaClass):
    for method in class_.methods:
        if method.name == "init":
            return method
    return None

class Document(BaseDocument):
    def __init__(self, index, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._index = index
        self._header_level = 1

    @contextmanager
    def increase_header_level(self):
        self._header_level = self._header_level + 1
        yield
        self._header_level = self._header_level = self._header_level - 1

    def add_header(self, text):
        super().add_header(text, self._header_level)

    def add_raw(self, text):
        text = self._replace_symbol_links(text)
        self.add_element(RawElement(text))

    def add_bold_paragraph(self, text):
        text = self._replace_symbol_links(text)
        self.add_element(Paragraph([InlineText(text).bold()]))

    def _replace_symbol_links(self, text, add_link=True):
        for symbol, name, anchor in self._index:
            replacement = f"<a href='{anchor}'>{name}</a>" if add_link else f"{name}"
            text = sub(r"%s" % escape(symbol), replacement, text)
        text = sub(r"vim\.api\.([\w|_]*)", r"[\1](https://neovim.io/doc/user/api.html#\1())", text)
        return text

    def add_module(self, module: LuaModule):
        if module.is_class_mod:
            self._add_class(
                module.classes[0],
                name=module.name,
                short_desc=module.short_desc,
                desc=module.desc,
            )
        else:
            self.add_header(f"{module.name}")
            self.add_raw(module.short_desc)
            self.add_raw(module.desc)
            self.add_horizontal_rule()
            classes = list([it for it in module.classes if not it.is_enum])
            enums = list([it for it in module.classes if it.is_enum])

            with self.increase_header_level():
                if enums:
                    self.add_header("Enums")
                    with self.increase_header_level():
                        for enum in enums:
                            self._add_enum(enum)

                if module.functions:
                    self.add_header("Methods")
                    with self.increase_header_level():
                        for function in module.functions:
                            self._add_function(function)
                if classes:
                    self.add_header("Classes")
                    with self.increase_header_level():
                        for class_ in classes:
                            self._add_class(class_)

    def _add_class(
        self,
        class_: LuaClass,
        name: str | None = None,
        short_desc: str | None = None,
        desc: str | None = None,
    ):
        desc = desc or class_.desc
        name = name or class_.name
        short_desc = short_desc or class_.short_desc
        assert name is not None

        self.add_header(f"{name.split('.')[-1]}")

        if short_desc:
            self.add_raw(short_desc)

        if desc:
            self.add_raw(desc)

        with self.increase_header_level():
            constructor = get_constructor(class_)
            if constructor:
                self.add_header("Constructor")
                self._add_contsructor(constructor, class_.name.split(".")[-1])

            if class_.fields:
                self.add_header("Fields")

            properties = self._get_properties(class_)
            if properties:
                self.add_header("Properties")

                self.add_table(
                    ["Name", "Type", "Access", "Description"],
                    [
                        [
                            f"```{name}```",
                            f"<code>{property['type']}</code>",
                            get_access_string(property),
                            self._replace_symbol_links(property["desc"])
                        ]
                        for (name, property) in properties.items()
                    ],
                    align=[
                        Table.Align.CENTER,
                        Table.Align.CENTER,
                        Table.Align.CENTER,
                        Table.Align.LEFT,
                    ],
                )

            methods = get_methods(class_)
            if methods:
                self.add_header("Methods")

                with self.increase_header_level():
                    for method in methods:
                        self._add_function(method, class_name=class_.name.split('.')[-1])

    def _get_properties(self, class_: LuaClass):
        properties: dict[str, (LuaFunction|None, LuaFunction|None)] = {}
        for method in class_.methods:
            name = method.name
            if not name.startswith("properties"):
                continue
            splitted_name = name.split(".")
            property_name = splitted_name[1]
            if not property_name in properties:
                properties[property_name] = dict(
                        desc = "",
                        get = False,
                        set = False,
                        type = None
                )

            property = properties[property_name]
            if splitted_name[2] == "get":
                property["get"] = True
                property["type"] = ", ".join(
                    [self._get_type_string(it.type) for it in method.returns]
                )
                property["desc"] = f"{property['desc']} {method.short_desc} {method.desc}"
            else:
                properties[property_name]["set"] = True
                if not property["type"]:
                    property["type"] = ", ".join(
                    [self._get_type_string(it.type) for it in method.params]
                )
                property["desc"] = f"{property['desc']} {method.short_desc} {method.desc}"


        return properties

    def _add_enum(
        self,
        enum: LuaClass,
    ):
        self.add_header(f"{enum.name.split('.')[-1]}")

        if enum.short_desc:
            self.add_raw(enum.short_desc)

        if enum.desc:
            self.add_raw(enum.desc)

        self.add_table(
            ["Member", "Description"],
            [
                [
                    f"```{field.name}```",
                    field.desc,
                ]
                for field in enum.fields
            ],
            align=[
                Table.Align.LEFT,
                Table.Align.LEFT,
            ],
        )

    def _add_parameters(self, function: LuaFunction, scope = ""):
        if not function.params:
            return

        self.add_table(
            ["Parameter", "Type", "Description", "Default"],
            [
                [
                    f"```{param.name}```" if param.is_opt else f"```{param.name}```*",
                    f"<code>{self._get_type_string(param.type)}</code>",
                    param.desc,
                    param.default_value,
                ]
                for param in function.params
            ],
            align=[
                Table.Align.LEFT,
                Table.Align.LEFT,
                Table.Align.LEFT,
                Table.Align.LEFT,
            ],
        )

    def _get_signature(self, function: LuaFunction):
        arguments = ", ".join(
            [
                f"{it.name}: {self._get_type_string(it.type, False)}"
                for it in function.params
            ]
        )
        if function.returns:
            returns = ", ".join(
                [self._get_type_string(it.type, False) for it in function.returns]
            )
        else:
            returns = "nil"

        return arguments, returns

    def _add_contsructor(self, constructor: LuaFunction, class_name: str):
        if constructor.visibility == "private":
            return

        self.add_bold_paragraph(f"Signature")

        arguments, returns = self._get_signature(constructor)

        self.add_code(
            f"{class_name}({arguments})", lang="lua"
        )

        self._add_parameters(constructor)

        if constructor.desc:
            self.add_bold_paragraph("Notes")
            self.add_raw(constructor.desc)

        if constructor.usage:
            self.add_bold_paragraph("Usage")
            self.add_code(constructor.usage, lang="lua")

    def _add_function(self, function: LuaFunction, class_name=""):
        if function.visibility == "private":
            return

        self.add_header(f"{function.name}()")
        self.add_raw(function.short_desc)
        self.add_bold_paragraph(f"Signature")

        arguments, returns = self._get_signature(function)

        if class_name:
            if function.is_static:
                scope = f"{class_name}."
            else:
                scope = f"{class_name}:"
        else:
            scope = ""

        self.add_code(
            f"function {scope}{function.name}({arguments}) -> {returns}", lang="lua"
        )

        self._add_parameters(function)

        if function.returns:
            self.add_table(
                ["Returns", "Description"],
                [
                    [
                        f"<code>{self._get_type_string(it.type)}</code>",
                        it.desc,
                    ]
                    for it in function.returns
                ],
                align=[
                    Table.Align.LEFT,
                    Table.Align.LEFT,
                ],
            )

        if function.desc:
            self.add_bold_paragraph("Notes")
            self.add_raw(function.desc)

        if function.usage:
            self.add_bold_paragraph("Usage")
            self.add_code(function.usage, lang="lua")

        self.add_horizontal_rule()

    def _get_type_string(self, type_: LuaType, link_symbols=True):
        if isinstance(type_, LuaTypeAny):
            return "any"
        if isinstance(type_, LuaTypeCallable):
            arg_types = ", ".join([self._get_type_string(it) for it in type_.arg_types])
            return_types = list(
                [self._get_type_string(it) for it in type_.return_types]
            )

            if len(return_types) == 1:
                return_type = return_types[0]
            else:
                return_type = f"({', '.join(return_types)})"
            return f"function({arg_types}):{return_type}"
        if isinstance(type_, LuaTypeCustom):
            return self._replace_symbol_links(type_.name, link_symbols)
        if isinstance(type_, LuaTypeFunction):
            return self._replace_symbol_links(type_.id, link_symbols)
        if isinstance(type_, LuaTypeString):
            return "string"
        if isinstance(type_, LuaTypeBoolean):
            return "string"
        if isinstance(type_, LuaTypeNumber):
            return "number"

        assert False


def get_anchor(symbol_name: str) -> str:
    return symbol_name.lower()


class Generator:
    def __init__(self):
        self._index = []

    def generate(self):
        modules = []
        source_root = Path.cwd() / "lua/jnvim"
        doc_root = Path.cwd() / "doc/api"
        for source_path in source_root.glob("**/*.lua"):
            doc_path = doc_root / source_path.relative_to(source_root).with_suffix(
                ""
            ).with_suffix(".md")

            doc_parser = DocParser(DocOptions())
            with open(source_path, "r") as source:
                module = doc_parser.build_module_doc_model(
                    source.read(), str(source_path)
                )
            self._index_symbols(module, doc_path)
            modules.append((module, doc_path))

        self._index = sorted(self._index, key=lambda id: len(id[0]), reverse=True)
        for (module, doc_path) in modules:
            markdown = Document(self._index, doc_path.name)
            markdown.add_module(module)

            doc_path.parent.mkdir(parents=True, exist_ok=True)
            with open(doc_path, "w") as doc:
                doc.write(str(markdown))

    def _index_symbol(
            self, doc_url: str, id: str, symbol: LuaClass | LuaFunction, link_text = None
    ) -> None:
        link_text = link_text or symbol.name
        self._index.append((id, link_text, f"/{doc_url}/#{get_anchor(link_text)}"))

    def _index_symbols(self, module: LuaModule, doc_path: Path) -> dict[str, str]:
        doc_url = str(doc_path.relative_to(Path.cwd() / "doc").with_suffix(""))
        self._index.append((module.name, module.name, f"/{doc_url}"))
        for class_ in module.classes:
            self._index_symbol(doc_url, class_.name, class_, class_.name.split(".")[-1])
            for method in class_.methods:
                name = method.name
                if not name.startswith("properties"):
                    self._index_symbol(
                        doc_url, f"{class_.name}.{name}", method
                    )
                else:
                    name = name.split('.')[-2]
                    self._index_symbol(
                        doc_url, f"{class_.name}.{name}", class_,
                        f"{class_.name.split('.')[-1]}.{name}"

                    )
            if class_.is_enum:
                for field in class_.fields:
                    self._index_symbol(
                        doc_url, f"{class_.name}.{field.name}", class_, f"{class_.name.split('.')[-1]}.{field.name}"
                    )

        for function in module.functions:
            self._index_symbol(doc_url, f"{module.name}.{function.name}", function)


Generator().generate()

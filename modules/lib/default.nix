{lib}: {
  attrsets = import ./attrsets {inherit lib;};
  generators = import ./generators {inherit lib;};
  types = import ./types {inherit lib;};
}

{lib}: {
  # lib is extended under lib.rum due to annoyances with lib extensions
  # and also to maximize transparency of what is and isn't custom
  rum = {
    attrsets = import ./attrsets {inherit lib;};
    generators = import ./generators {inherit lib;};
    options = import ./options {inherit lib;};
    types = import ./types {inherit lib;};
  };
}

{lib}: let
  inherit (builtins) any isList toString;
  inherit (lib.attrsets) filterAttrs mapAttrsToList;
  inherit (lib.strings) concatStringsSep hasPrefix;

  toEnv = env:
    if isList env
    then concatStringsSep ":" (map toString env)
    else toString env;

  filterKeysPrefix = filterPrefixes: attrs: let
    filteredVars =
      if filterPrefixes == []
      then attrs
      else
        filterAttrs
        (name: _: any (prefix: hasPrefix prefix name) filterPrefixes)
        attrs;
  in
    concatStringsSep "\n"
    (mapAttrsToList (name: value: "export ${name}=\"${toEnv value}\"") filteredVars);
in {
  inherit filterKeysPrefix toEnv;
}

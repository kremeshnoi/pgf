{
  lib,
  stdenvNoCC,
  makeBinaryWrapper,
  bash,
  coreutils,
  gnugrep,
  gnused,
  gawk,
  fzf,
  postgresql,
  pspg,
}:

stdenvNoCC.mkDerivation {
  pname = "pgf";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [ ./bin ./queries ];
  };

  nativeBuildInputs = [ makeBinaryWrapper ];
  buildInputs = [ bash ];

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/pgf $out/libexec/pgf/pgf
    mkdir -p $out/share/pgf
    cp -R queries $out/share/pgf/queries
    patchShebangs $out/libexec/pgf/pgf
    makeBinaryWrapper $out/libexec/pgf/pgf $out/bin/pgf \
      --prefix PATH : ${lib.makeBinPath [ coreutils gnugrep gnused gawk fzf postgresql pspg ]} \
      --set-default PGF_BUILTIN_QUERIES $out/share/pgf/queries \
      --set-default PSQL_PAGER pspg
    runHook postInstall
  '';

  meta = {
    description = "fzf picker for psql services and saved queries";
    mainProgram = "pgf";
    platforms = lib.platforms.unix;
  };
}

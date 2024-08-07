{ lib
, rustPlatform
, fetchFromGitHub
, installShellFiles
, stdenv
, darwin
, rust-jemalloc-sys
, ruff-lsp
, testers
, ruff
}:

rustPlatform.buildRustPackage rec {
  pname = "ruff";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "astral-sh";
    repo = "ruff";
    rev = "refs/tags/${version}";
    hash = "sha256-OjMoa247om4DLPZ6u0XPMd5L+LYlVzHL39plCCr/fYE=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "lsp-types-0.95.1" = "sha256-8Oh299exWXVi6A39pALOISNfp8XBya8z+KT/Z7suRxQ=";
      "salsa-0.18.0" = "sha256-keVEmSwV1Su1RlOTaIu253FZidk279qA+rXcCeuOggc=";
    };
  };

  nativeBuildInputs = [
    installShellFiles
  ];

  buildInputs = [
    rust-jemalloc-sys
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.CoreServices
  ];

  # tests expect no colors
  preCheck = ''
    export NO_COLOR=1
  '';

  # Failing for an unclear reason.
  # According to the maintainers, those tests are from an experimental crate that isn't actually
  # used by ruff currently and can thus be safely skipped.
  checkFlags = [
    "--skip=semantic::tests::expression_scope"
    "--skip=semantic::tests::reachability_trivial"
    "--skip=semantic::types::infer::tests::follow_import_to_class"
    "--skip=semantic::types::infer::tests::if_elif"
    "--skip=semantic::types::infer::tests::if_elif_else"
    "--skip=semantic::types::infer::tests::ifexpr_walrus"
    "--skip=semantic::types::infer::tests::ifexpr_walrus_2"
    "--skip=semantic::types::infer::tests::join_paths"
    "--skip=semantic::types::infer::tests::literal_int_arithmetic"
    "--skip=semantic::types::infer::tests::maybe_unbound"
    "--skip=semantic::types::infer::tests::narrow_none"
    "--skip=semantic::types::infer::tests::resolve_base_class_by_name"
    "--skip=semantic::types::infer::tests::resolve_module_member"
    "--skip=semantic::types::infer::tests::resolve_visible_def"
  ];

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd ruff \
      --bash <($out/bin/ruff generate-shell-completion bash) \
      --fish <($out/bin/ruff generate-shell-completion fish) \
      --zsh <($out/bin/ruff generate-shell-completion zsh)
  '';

  passthru.tests = {
    inherit ruff-lsp;
    version = testers.testVersion { package = ruff; };
  };

  meta = {
    description = "Extremely fast Python linter";
    homepage = "https://github.com/astral-sh/ruff";
    changelog = "https://github.com/astral-sh/ruff/releases/tag/${version}";
    license = lib.licenses.mit;
    mainProgram = "ruff";
    maintainers = with lib.maintainers; [
      figsoda
      GaetanLepage
    ];
  };
}

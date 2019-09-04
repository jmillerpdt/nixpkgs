{ stdenv, lib, fetchFromGitHub, substituteAll, cmake, bash
, version ? "1.2.1"
, mklSupport ? false, mkl ? null }:

assert !mklSupport || mkl != null;

stdenv.mkDerivation rec {
  pname = "dnnl";
  inherit version;

  # mkl optimizations are added directly to dnnl in version 1.0 and above
  optMkl = stdenv.lib.versionOlder version "1.0" && mklSupport;

  src = fetchFromGitHub {
    owner = "intel";
    repo = "mkl-dnn";
    rev = "v${version}";
    sha256 =
      if version == "1.2.1" then "17bydid5v43lgwvgxv25i67iiyirmwgbdzvv9wpjig34ryhx8hvf"
      else if version == "0.21.4" then "16x8pgwb6ds9lpclyl4jlz8xhmbcdqk7v4s6k3bnliqs04s3ldfw"
      else throw "unsupported version ${version} for dnnl";
  };


  # Generic fix merged upstream in https://github.com/intel/mkl-dnn/pull/631
  # Delete after next release
  patchPhase = ''
    substituteInPlace tests/CMakeLists.txt \
      --replace /bin/bash ${bash}/bin/bash
  '';

  outputs = [ "out" "dev" "doc" ];

  nativeBuildInputs = [ cmake ];

  buildInputs = lib.optionals (optMkl) [ mkl ];

  doCheck = true;

  # The test driver doesn't add an RPath to the build libdir
  preCheck = ''
    export LD_LIBRARY_PATH=$PWD/src
  '';

  # The cmake install for 1.x gets tripped up and installs a nix tree into $out, in
  # addition to the correct install; clean it up.
  postInstall = ''
    [ ! -d $out/nix ] || rm -r $out/nix
  '';

  meta = with lib; {
    description = "Deep Neural Network Library (DNNL)";
    homepage = "https://intel.github.io/mkl-dnn/dev_guide_transition_to_dnnl.html";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ alexarice bhipple ];
  };
}

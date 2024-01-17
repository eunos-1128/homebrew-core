class Sfcgal < Formula
  desc "C++ wrapper library around CGAL"
  homepage "https://sfcgal.gitlab.io/SFCGAL/"
  url "https://gitlab.com/sfcgal/SFCGAL/-/archive/v1.5.1/SFCGAL-v1.5.1.tar.gz"
  sha256 "ea5d1662fada7de715ad564dc810c3059024ed81ae393f5352489f706fdfa3b1"
  license "LGPL-2.0-or-later"

  bottle do
    sha256 cellar: :any,                 arm64_sonoma:   "7a9b7c29901a9e1b267511456b3ce11039cd88c865ea32e056e8cf79deb92a5c"
    sha256 cellar: :any,                 arm64_ventura:  "002d649da42e0828a60ebb9244dd0bf76988c0c64972079191db234fc80b1cf6"
    sha256 cellar: :any,                 arm64_monterey: "eac1d2e955ad287d4e4666431f479655916e964ad77a1ccc033aeb06696845ca"
    sha256 cellar: :any,                 sonoma:         "393570b456f2c887e1401fb04492782cbf723f1cc3e976cad994a97ab94aac02"
    sha256 cellar: :any,                 ventura:        "ce162156abadb2e65e7842a55a5a4876d69a0aeebafab8592c34b4c20ef9206e"
    sha256 cellar: :any,                 monterey:       "71b2a4230207167d51f1f7d8fcbfc7615ec3db27550cd5e24ded36f0b5c1cfe9"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "4a34a0545d5096fc817d0e5e61474154931512f2aa4d2b4ed02e42f5563954fa"
  end

  depends_on "cmake" => :build
  depends_on "boost"
  depends_on "cgal"
  depends_on "gmp"
  depends_on "mpfr"

  # error: array must be initialized with a brace-enclosed initializer
  fails_with gcc: "5"

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    assert_equal prefix.to_s, shell_output("#{bin}/sfcgal-config --prefix").strip
  end
end

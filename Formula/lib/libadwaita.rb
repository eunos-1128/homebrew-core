class Libadwaita < Formula
  desc "Building blocks for modern adaptive GNOME applications"
  homepage "https://gnome.pages.gitlab.gnome.org/libadwaita/"
  url "https://download.gnome.org/sources/libadwaita/1.6/libadwaita-1.6.3.tar.xz"
  sha256 "c88d4516edd1e0fc61be925f414efc340e149171756064473a082b6ae9a5dc00"
  license "LGPL-2.1-or-later"

  # libadwaita doesn't use GNOME's "even-numbered minor is stable" version
  # scheme. This regex is the same as the one generated by the `Gnome` strategy
  # but it's necessary to avoid the related version scheme logic.
  livecheck do
    url :stable
    regex(/libadwaita-(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 arm64_sequoia: "26f03d653282691ea5ce0a2c18cb2ad28da43d553c37de6423e76c6271127533"
    sha256 arm64_sonoma:  "da53f281421f826009214c96000d2a4f5b228150bc5245eef3743454e9d936aa"
    sha256 arm64_ventura: "c1deafb1abce0608225f2ce3ab73bcc3aaee43ee2e1b3ec49f99455429f3e840"
    sha256 sonoma:        "43226479d6a2e6b1781b3166f214bd28fd4fa293b193e74f6b12508ca9e3bdd1"
    sha256 ventura:       "cc25af66e1d985d6ae2b8f6feb619c805b6ceea9c83820e4661ce78d439230c7"
    sha256 x86_64_linux:  "c1c215c269ad6fe0870581f8ac085f9c2184ea4e92a13d3f3c9f9c68c9140ca5"
  end

  depends_on "gettext" => :build
  depends_on "gobject-introspection" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on "sassc" => :build
  depends_on "vala" => :build

  depends_on "appstream"
  depends_on "fribidi"
  depends_on "glib"
  depends_on "graphene"
  depends_on "gtk4"
  depends_on "libsass"
  depends_on "pango"

  uses_from_macos "python" => :build

  on_macos do
    depends_on "gettext"
  end

  def install
    system "meson", "setup", "build", "-Dtests=false", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <adwaita.h>

      int main(int argc, char *argv[]) {
        g_autoptr (AdwApplication) app = NULL;
        app = adw_application_new ("org.example.Hello", G_APPLICATION_DEFAULT_FLAGS);
        return g_application_run (G_APPLICATION (app), argc, argv);
      }
    C
    flags = shell_output("#{Formula["pkgconf"].opt_bin}/pkgconf --cflags --libs libadwaita-1").strip.split
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test", "--help"

    # include a version check for the pkg-config files
    assert_match version.to_s, (lib/"pkgconfig/libadwaita-1.pc").read
  end
end

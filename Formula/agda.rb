class Agda < Formula
  desc "Dependently typed functional programming language"
  homepage "https://wiki.portal.chalmers.se/agda/"
  license "BSD-3-Clause"
  revision 3

  stable do
    url "https://hackage.haskell.org/package/Agda-2.6.1.3/Agda-2.6.1.3.tar.gz"
    sha256 "bb1bc840cee95eea291bd220ea043b60153a6f7bd8198bc53be2bf3b83c8a1e7"

    resource "stdlib" do
      url "https://github.com/agda/agda-stdlib/archive/v1.6.tar.gz"
      sha256 "9dbfb6627d84cdb1db500d69a3ab2aad486e058e42c3ceddb8d9047fc74a84dc"
    end
  end

  bottle do
    sha256 arm64_big_sur: "8791de9da2d33e6e3411907a3e46ff5a53525c22a695a16c99e31118d345b712"
    sha256 big_sur:       "a17b2a185083a45a26f4c8cfbc49561f2d3f0d90b1e4d069dd0ecab4b10fd2af"
    sha256 catalina:      "2856aebd3cc86c88c55f2445982670ae2494eae9521995dc8dd8da1fc43776f2"
    sha256 mojave:        "1c3a40bd0ec48c5963b3b5a140f3bb203abd42d6101389c7f6ac69723b334335"
  end

  head do
    url "https://github.com/agda/agda.git"

    resource "stdlib" do
      url "https://github.com/agda/agda-stdlib.git"
    end
  end

  depends_on "llvm" => [:build, :test] if Hardware::CPU.arm?
  depends_on "cabal-install"
  depends_on "emacs"
  depends_on "ghc"

  uses_from_macos "zlib"

  resource "alex" do
    url "https://hackage.haskell.org/package/alex-3.2.6/alex-3.2.6.tar.gz"
    sha256 "91aa08c1d3312125fbf4284815189299bbb0be34421ab963b1f2ae06eccc5410"
  end

  resource "cpphs" do
    url "https://hackage.haskell.org/package/cpphs-1.20.9.1/cpphs-1.20.9.1.tar.gz"
    sha256 "7f59b10bc3374004cee3c04fa4ee4a1b90d0dca84a3d0e436d5861a1aa3b919f"
  end

  resource "happy" do
    url "https://hackage.haskell.org/package/happy-1.20.0/happy-1.20.0.tar.gz"
    sha256 "3b1d3a8f93a2723b554d9f07b2cd136be1a7b2fcab1855b12b7aab5cbac8868c"
  end

  def install
    ENV["CABAL_DIR"] = prefix/"cabal"
    system "cabal", "v2-update"
    cabal_args = std_cabal_v2_args.reject { |s| s["installdir"] }

    # happy must be installed before alex
    %w[happy alex cpphs].each do |r|
      r_installdir = libexec/r/"bin"
      ENV.prepend_path "PATH", r_installdir

      resource(r).stage do
        mkdir r_installdir
        system "cabal", "v2-install", *cabal_args, "--installdir=#{r_installdir}"
      end
    end

    system "cabal", "v2-install", "-f", "cpphs", *std_cabal_v2_args

    # generate the standard library's documentation and vim highlighting files
    resource("stdlib").stage lib/"agda"
    cd lib/"agda" do
      system "cabal", "v2-install", *cabal_args, "--installdir=#{lib}/agda"
      system "./GenerateEverything"
      system bin/"agda", "-i", ".", "-i", "src", "--html", "--vim", "README.agda"
    end

    # Clean up references to Homebrew shims
    rm_rf "#{lib}/agda/dist-newstyle/cache"
  end

  test do
    ENV.append_path "PATH", Formula["llvm"].opt_bin

    simpletest = testpath/"SimpleTest.agda"
    simpletest.write <<~EOS
      module SimpleTest where

      data ℕ : Set where
        zero : ℕ
        suc  : ℕ → ℕ

      infixl 6 _+_
      _+_ : ℕ → ℕ → ℕ
      zero  + n = n
      suc m + n = suc (m + n)

      infix 4 _≡_
      data _≡_ {A : Set} (x : A) : A → Set where
        refl : x ≡ x

      cong : ∀ {A B : Set} (f : A → B) {x y} → x ≡ y → f x ≡ f y
      cong f refl = refl

      +-assoc : ∀ m n o → (m + n) + o ≡ m + (n + o)
      +-assoc zero    _ _ = refl
      +-assoc (suc m) n o = cong suc (+-assoc m n o)
    EOS

    stdlibtest = testpath/"StdlibTest.agda"
    stdlibtest.write <<~EOS
      module StdlibTest where

      open import Data.Nat
      open import Relation.Binary.PropositionalEquality

      +-assoc : ∀ m n o → (m + n) + o ≡ m + (n + o)
      +-assoc zero    _ _ = refl
      +-assoc (suc m) n o = cong suc (+-assoc m n o)
    EOS

    iotest = testpath/"IOTest.agda"
    iotest.write <<~EOS
      module IOTest where

      open import Agda.Builtin.IO
      open import Agda.Builtin.Unit

      postulate
        return : ∀ {A : Set} → A → IO A

      {-# COMPILE GHC return = \\_ -> return #-}

      main : _
      main = return tt
    EOS

    # we need a test-local copy of the stdlib as the test writes to
    # the stdlib directory
    resource("stdlib").stage testpath/"lib/agda"

    # typecheck a simple module
    system bin/"agda", simpletest

    # typecheck a module that uses the standard library
    system bin/"agda", "-i", testpath/"lib/agda/src", stdlibtest

    # compile a simple module using the JS backend
    system bin/"agda", "--js", simpletest

    # test the GHC backend
    cabal_args = std_cabal_v2_args.reject { |s| s["installdir"] }
    system "cabal", "v2-update"
    system "cabal", "v2-install", "ieee754", "--lib", *cabal_args

    # compile and run a simple program
    system bin/"agda", "-c", iotest
    assert_equal "", shell_output(testpath/"IOTest")
  end
end

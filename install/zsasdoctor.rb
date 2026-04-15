class Zsasdoctor < Formula
  desc "SAS Developer Environment Doctor Tool"
  homepage "https://github.com/hariharan-rs-19343/zsasdoctor"
  url "https://github.com/hariharan-rs-19343/zsasdoctor/archive/refs/tags/v1.0.0.zip"
  sha256 "653c166ab91ebef257b1d5e518bbf71199a803e5c9ed51a85918596fdb01e4b7"
  license "MIT"

  def install
    bin.install "bin/zsasdoctor"
    lib.install Dir["lib/*"]
    (etc/"zsasdoctor").install Dir["config/*"]
  end

  test do
    system "#{bin}/zsasdoctor", "version"
  end
end

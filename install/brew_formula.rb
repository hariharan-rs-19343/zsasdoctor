class Zsasdoctor < Formula
  desc "SAS Developer Environment Doctor Tool"
  homepage "https://github.com/your-org/zsasdoctor"
  url "https://github.com/your-org/zsasdoctor/archive/v1.0.0.tar.gz"
  sha256 "<SHA256_HASH>"
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

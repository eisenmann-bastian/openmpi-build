import os
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "build.sh"


class NativeBuildTests(unittest.TestCase):
    def test_rejects_non_linux(self):
        with tempfile.TemporaryDirectory() as temporary:
            fake_uname = Path(temporary) / "uname"
            fake_uname.write_text("#!/bin/sh\nprintf 'Darwin\\n'\n", encoding="utf-8")
            fake_uname.chmod(0o755)
            env = {**os.environ, "PATH": f"{temporary}{os.pathsep}{os.environ['PATH']}"}
            result = subprocess.run(
                [str(SCRIPT)], env=env, capture_output=True, text=True, check=False
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("must run natively on Linux", result.stderr)

    def test_refuses_to_overwrite_existing_archive(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            fake_uname = root / "uname"
            fake_uname.write_text(
                "#!/bin/sh\ncase \"$1\" in -s) echo Linux;; -m) echo aarch64;; esac\n",
                encoding="utf-8",
            )
            fake_uname.chmod(0o755)
            output = root / "output"
            output.mkdir()
            archive = output / "openmpi-4.1.8-linux-arm64.tar.gz"
            archive.write_text("existing", encoding="utf-8")
            env = {
                **os.environ,
                "PATH": f"{root}{os.pathsep}{os.environ['PATH']}",
                "OPENMPI_OUTPUT_DIR": str(output),
            }
            result = subprocess.run(
                [str(SCRIPT)], env=env, capture_output=True, text=True, check=False
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Archive already exists", result.stderr)
            self.assertEqual(archive.read_text(encoding="utf-8"), "existing")


if __name__ == "__main__":
    unittest.main()

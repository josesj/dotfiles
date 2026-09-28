"""Add an “Open in Visual Studio Code” action to Nautilus folders."""

from __future__ import annotations

import subprocess
from pathlib import Path

from gi.repository import GObject, Nautilus


class OpenInVisualStudioCodeExtension(GObject.GObject, Nautilus.MenuProvider):
    """Open a selected local folder, or the current folder, in VS Code."""

    @staticmethod
    def _local_directory(file_info: Nautilus.FileInfo) -> Path | None:
        if file_info.get_uri_scheme() != "file" or not file_info.is_directory():
            return None

        location = file_info.get_location()
        path = location.get_path() if location is not None else None
        return Path(path) if path else None

    @staticmethod
    def _open_directory(_item: Nautilus.MenuItem, directory: Path) -> None:
        subprocess.Popen(
            ["code", "--new-window", str(directory)],
            cwd=directory,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )

    def _menu_item(
        self, file_info: Nautilus.FileInfo, item_name: str
    ) -> Nautilus.MenuItem | None:
        directory = self._local_directory(file_info)
        if directory is None:
            return None

        item = Nautilus.MenuItem(
            name=f"OpenInVisualStudioCode::{item_name}",
            label="Open in Visual Studio Code",
            tip=f"Open {directory.name or directory} in Visual Studio Code",
            icon="vscode",
        )
        item.connect("activate", self._open_directory, directory)
        return item

    def get_file_items(
        self, files: list[Nautilus.FileInfo]
    ) -> list[Nautilus.MenuItem]:
        if len(files) != 1:
            return []
        item = self._menu_item(files[0], "SelectedFolder")
        return [item] if item is not None else []

    def get_background_items(
        self, current_folder: Nautilus.FileInfo
    ) -> list[Nautilus.MenuItem]:
        item = self._menu_item(current_folder, "CurrentFolder")
        return [item] if item is not None else []

_: {
  systemd.user.slices."gaming" = {
    Unit = {
      Description = "Prefer keeping game memory in RAM";
    };
    Slice = {
      # Best-effort protection; swap remains available under memory pressure.
      MemoryLow = "8G";
    };
  };
}

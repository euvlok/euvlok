_: {
    systemd.user.slices."no-swap" = {
    Unit = {
      Description = "Disable swap for slice";
    };
    Slice = {
      MemorySwapMax = "0";
      OOMScoreAdjust = "1000";
    };
  };
}
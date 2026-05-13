# Hardware acceleration configuration for ledatel
# This file configures GPU drivers and hardware acceleration
{
  pkgs,
  ...
}:

{
  # TODO: Configure the appropriate GPU driver for your hardware

  # For Intel integrated graphics (most common in laptops):
  # machine.intel.enable = true; # This option doesn't exist yet in your modules

  # For NVIDIA graphics:
  # machine.nvidia.enable = true;

  # For AMD graphics:
  # machine.amd.enable = true;

  # Basic hardware acceleration (works with most GPUs)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      # Intel
      intel-media-driver
      intel-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl

      # Common packages
      libva
      libva-utils
    ];
  };

  # Enable 32-bit support if needed (gaming, some applications)
  hardware.graphics.enable32Bit = true;

  # Example configurations (uncomment and modify as needed):

  # If you have Intel integrated graphics:
  # boot.kernelModules = [ "i915" ];
  # environment.variables = {
  #   VDPAU_DRIVER = lib.mkIf config.hardware.graphics.enable (lib.mkDefault "va_gl");
  # };

  # If you have hybrid graphics (Intel + NVIDIA), you might want:
  # hardware.graphics.extraPackages32 = with pkgs.driversi686Linux; [
  #   intel-media-driver
  #   vaapiIntel
  # ];

  # Vulkan support (for gaming/graphics applications):
  # hardware.graphics.extraPackages = with pkgs; [
  #   vulkan-loader
  #   vulkan-validation-layers
  #   vulkan-extension-layer
  # ];
}

{ inputs, ... }:
{
  null = (import ./null { inherit inputs; }).null;
  laptop = (import ./laptop { inherit inputs; }).laptop;
  ledatel = (import ./ledatel { inherit inputs; }).ledatel;
  zero = (import ./zero { inherit inputs; }).zero;
}

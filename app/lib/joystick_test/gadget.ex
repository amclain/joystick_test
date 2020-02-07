defmodule JoystickTest.Gadget do
  @moduledoc """
  Manage the system's USB gadget device.
  """

  require Logger

  @gadget_name "hidg"

  @doc """
  Configure the USB gadget device.
  Call this function on application startup.
  """
  def configure do
    :os.cmd('mount -t configfs none /sys/kernel/config')

    device_settings = %{
      "bcdUSB" => "0x0200",
      "bDeviceClass" => "0xEF",
      "bDeviceSubClass" => "0x02",
      "bDeviceProtocol" => "0x01",
      "idVendor" => "0x1209",
      "idProduct" => "0x0071",
      "bcdDevice" => "0x0100",
      "os_desc" => %{
        "use" => "1",
        "b_vendor_code" => "0xcd",
        "qw_sign" => "MSFT100"
      },
      "strings" => %{
        "0x409" => %{
          "manufacturer" => "Alex McLain",
          "product" => "Joystick Test",
          "serialnumber" => ""
        }
      }
    }

    hid_keyboard_settings = %{
      "protocol" => "1",
      "report_length" => "8",
      "subclass" => "1",
      "report_desc" =>
        <<0x05, 0x01, 0x09, 0x06, 0xA1, 0x01, 0x05, 0x07, 0x19, 0xE0, 0x29, 0xE7, 0x15, 0x00,
          0x25, 0x01, 0x75, 0x01, 0x95, 0x08, 0x81, 0x02, 0x81, 0x01, 0x19, 0x00, 0x29, 0xFF,
          0x15, 0x00, 0x25, 0xFF, 0x75, 0x08, 0x95, 0x06, 0x81, 0x00, 0x05, 0x08, 0x19, 0x01,
          0x29, 0x05, 0x15, 0x00, 0x25, 0x01, 0x75, 0x01, 0x95, 0x05, 0x91, 0x02, 0x95, 0x03,
          0x91, 0x01, 0xC0>>
    }

    config1_settings = %{
      "bmAttributes" => "0xC0",
      "MaxPower" => "500",
      "strings" => %{
        "0x409" => %{
          "configuration" => "HID Keyboard"
        }
      }
    }

    function_list = ["hid.usb0"]

    with {:create_device, :ok} <-
           {:create_device, USBGadget.create_device(@gadget_name, device_settings)},
         {:create_acm, :ok} <-
           {:create_acm, USBGadget.create_function(@gadget_name, "hid.usb0", hid_keyboard_settings)},
         {:create_config, :ok} <-
           {:create_config, USBGadget.create_config(@gadget_name, "c.1", config1_settings)},
         {:link_functions, :ok} <-
           {:link_functions, USBGadget.link_functions(@gadget_name, "c.1", function_list)},
         {:link_os_desc, :ok} <- {:link_os_desc, USBGadget.link_os_desc(@gadget_name, "c.1")} do
    else
      {failed_step, {:error, reason}} ->
        throw "USB gadget init failed:\n#{failed_step}\n#{reason}"
    end

    reload_gadget_device

    Logger.info "USB gadget initialized"
  end

  defp reload_gadget_device do
    :os.cmd('rmmod g_cdc')
    USBGadget.disable_device(@gadget_name)

    USBGadget.enable_device(@gadget_name)
  end
end

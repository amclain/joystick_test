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

    device_definition = %{
      "bcdUSB" => "0x0200",        # USB specification release 2.0
      "bDeviceClass" => "0x03",    # HID device
      "bDeviceSubClass" => "0x00", # Unused with HID devices
      "bDeviceProtocol" => "0x00", # Device doesn't supoort a boot interface
      "idVendor" => "0x1209",
      "idProduct" => "0x0071",
      "bcdDevice" => "0x0001",     # Device release number, assigned by manufacturer
      "os_desc" => %{
        "use" => "1",
        "b_vendor_code" => "0xcd",
        "qw_sign" => "MSFT100"
      },
      "strings" => %{
        "0x409" => %{
          "manufacturer" => "",
          "product" => "Joystick Test",
          "serialnumber" => ""
        }
      }
    }

    joystick_function = %{
      "report_length" => "1",
      "report_desc" => <<
        0x05, 0x01, # UsagePage (Generic Desktop)
        0x09, 0x04, # Usage (Joystick)
        0xA1, 0x01, # Collection (Application)
          0x05, 0x09, # UsagePage (Buttons)
          0x19, 0x01, # Usage Minimum (Button 1),
          0x29, 0x04, # Usage Maximum (Button 4),
          0x15, 0x00, # Logical Minimum (0),
          0x25, 0x01, # Logical Maximum (1),
          0x95, 0x04, # Report Count (4),
          0x75, 0x01, # Report Size (1),
                      # Unit (None)
          0x81, 0x02, # Input (Data, Variable, Absolute)
        0xC0, # End Collection
      >>
    }

    joystick_config = %{
      "bmAttributes" => "0xC0",
      "MaxPower" => "500",
      "strings" => %{
        "0x409" => %{
          "configuration" => "HID Joystick"
        }
      }
    }

    function_list = ["hid.usb0"]

    with {:create_device, :ok} <-
           {:create_device, USBGadget.create_device(@gadget_name, device_definition)},
         {:create_acm, :ok} <-
           {:create_acm, USBGadget.create_function(@gadget_name, "hid.usb0", joystick_function)},
         {:create_config, :ok} <-
           {:create_config, USBGadget.create_config(@gadget_name, "c.1", joystick_config)},
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

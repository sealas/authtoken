# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
import Config

config :authtoken,
  token_key: <<1, 2, 3, 230, 103, 242, 149, 254, 4, 33, 137, 240, 23, 90, 99, 250>>

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :authtoken, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:authtoken, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

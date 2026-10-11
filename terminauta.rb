# frozen_string_literal: true

# terminauta: library entry (require "terminauta")

require_relative 'command/error'
require_relative 'command/option'
require_relative 'command/argument'
require_relative 'command/validators/base_validator'
require_relative 'command/class_methods'
require_relative 'command/state'
require_relative 'command/io'
require_relative 'command/ui'
require_relative 'command/parsing'
require_relative 'command/help'
require_relative 'command/dispatch'
require_relative 'command/base_command'
require_relative 'command/colored_command'

# Namespace for the terminauta CLI framework.
module Terminauta; end

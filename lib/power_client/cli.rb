# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Power Client.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Power Client is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Power Client. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Power Client, please visit:
# https://github.com/openflighthpc/power-client
#===============================================================================

require 'commander'
require 'power_client/config'
require 'power_client/commands'

module PowerClient
  VERSION = '0.2.2'

  class CLI
    extend Commander::Delegates

    program :name, 'power'
    program :version, PowerClient::VERSION
    program :description, 'Power on/off the cluster nodes'
    program :help_paging, false

    silent_trace!

    def self.run!
      ARGV.push '--help' if ARGV.empty?
      super
    end

    def self.action(command, klass, method: :run!)
      command.action do |args, options|
        hash = options.__hash__
        hash.delete(:trace)
        begin
          begin
            cmd = klass.new(*args, groups: hash.delete(:groups))
            hash.delete(:nodes)
            if hash.empty?
              cmd.public_send(method)
            else
              cmd.public_send(method, **hash)
            end
          rescue Interrupt
            raise RuntimeError, 'Received Interrupt!'
          end
        end
      end
    end

    def self.cli_syntax(command, standard: true)
      command.hidden = true if command.name.split.length > 1
      command.syntax = <<~SYNTAX.chomp
        #{program(:name)} #{command.name} #{'NODES[_GROUPS]...' if standard }
      SYNTAX
    end

    def self.shared_options(command)
      command.option '-n', '--nodes', 'DEPRECATED: Will be removed in the next release'
      command.option '-g', '--groups', 'Toggles the NODES name arguments to be GROUPS'
    end

    command 'list' do |c|
      cli_syntax(c, standard: false)
      c.summary = 'Return all the registed nodes [or groups]'
      c.option '-g', '--groups', 'Return the groups instead of nodes'
      c.option '-v', '--verbose', 'Return the nodes when used with --groups'
      action(c, Commands, method: :list)
    end

    command 'status' do |c|
      cli_syntax(c)
      c.summary = 'Get the current power status of the nodes'
      shared_options(c)
      action(c, Commands, method: :status)
    end

    command 'on' do |c|
      cli_syntax(c)
      c.summary = 'Turn the nodes on'
      shared_options(c)
      action(c, Commands, method: :on)
    end

    command 'off' do |c|
      cli_syntax(c)
      c.summary = 'Turn the nodes off'
      shared_options(c)
      action(c, Commands, method: :off)
    end

    command 'restart' do |c|
      cli_syntax(c)
      c.summary = 'Reboot the nodes'
      shared_options(c)
      action(c, Commands, method: :restart)
    end
  end
end

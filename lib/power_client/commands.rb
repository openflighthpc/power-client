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

require 'faraday'
require 'faraday_middleware'
require 'hashie'
require 'tty-table'
require 'uri'

module PowerClient
  Request = Struct.new(:names, :groups) do
    def self.connection
      @connection ||= Faraday.new(url: Config::Cache.base_url) do |conn|
        conn.authorization :Bearer, Config::Cache.jwt_token
        conn.use FaradayMiddleware::Mashify, :content_type => /\bjson$/
        conn.response :json, :content_type => /\bjson$/
        conn.adapter :net_http
      end
    end

    def status
      self.class.connection.get(path)
    end

    def on
      self.class.connection.patch(path)
    end

    def off
      self.class.connection.delete(path)
    end

    def restart
      self.class.connection.put(path)
    end

    private

    def path
      "/?#{groups ? 'groups' : 'nodes'}=#{URI.escape(names, '[]')}"
    end
  end

  class Commands
    attr_reader :names, :groups

    def initialize(*args, groups: false)
      @names = args.join(',')
      @groups = groups
    end

    def status
      run_request(:status) do |node|
        status = if node.attributes.success && node.attributes.running
                   'On'
                 elsif node.attributes.success
                   'Off'
                 else
                   'Unknown'
                 end
        [node.id, status]
      end
    end

    def on
      run_request(:on) do |node|
        status = if node.attributes.success
                   'Starting'
                 else
                   'Failed to start'
                 end
        [node.id, status]
      end
    end

    def off
      run_request(:off) do |node|
        status = if node.attributes.success
                   'Stopping'
                 else
                   'Failed to stop'
                 end
        [node.id, status]
      end
    end

    def restart
      run_request(:restart) do |node|
        status = if node.attributes.success
                   'Restarting'
                 else
                   'Failed to restart'
                 end
        [node.id, status]
      end
    end

    private

    def run_request(method)
      res = request.send(method)
      if res.success?
        rows = res.body.data.map { |n| yield n }
        puts TTY::Table.new(rows: rows).render
      elsif res.status == 403
        raise 'You do not have permission to access this content!'
      else
        raise 'An unexpected error has occurred!'
      end
    end

    def request
      @request ||= Request.new(names, groups)
    end
  end
end

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

module PowerClient
  Request = Struct.new(:nodes) do
    def status
      self.class.connection.get(path)
    end

    private

    def path
      "/nodes/#{nodes}"
    end

    def self.connection
      @connection ||= Faraday.new(url: Config::Cache.base_url) do |conn|
        conn.authorization :Bearer, Config::Cache.jwt_token
        conn.use FaradayMiddleware::Mashify, :content_type => /\bjson$/
        conn.response :json, :content_type => /\bjson$/
        conn.adapter :net_http
      end
    end
  end

  Commands = Struct.new(:raw_nodes) do
    def status
      pp request.status.body
    end

    def on
      pp request.on.body
    end

    def off
      pp request.off.body
    end

    private

    def request
      Request.new(nodes)
    end

    def nodes
      if raw_nodes
        raw_nodes
      else
        raise "the '--nodes NODES' flag is required"
      end
    end
  end
end

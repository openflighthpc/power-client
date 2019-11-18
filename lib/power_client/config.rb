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

require 'active_support/core_ext/module/delegation'
require 'hashie'

module PowerClient
  class Config < Hashie::Dash
    module Cache
      class << self
        def cache
          @cache ||= Config.new(YAML.load(File.read(path), symbolize_names: true))
        end

        def path
          File.expand_path('../../etc/config.yaml', __dir__)
        end

        delegate_missing_to :cache
      end
    end

    include Hashie::Extensions::IgnoreUndeclared

    property :base_url
    property :jwt_token
  end
end

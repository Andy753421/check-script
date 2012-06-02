# Copyright (C) 2007, 2008 Corey Kump
# Copyright (C) 2007, 2008 Jason Sauppe
# Copyright (C) 2007, 2008 Andy Spencer <spenceal@rose-hulman.edu>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class SubmittedFile < ActiveRecord::Base
	belongs_to :submission
	def initialize(file)
		super()
		self.filetype = case file.original_filename
		                when /\.(ss|sch)$/i; "text/scheme"
		                when /\.zip$/i;      "application/zip"
		                when /\.tar$/i;      "application/x-tar"
				when /\.rar$/i;	     "application/x-rar-compressed"
				when /\.gz$/i;	     "application/x-gzip"
				when /\.bz2$/i;      "application/x-bzip2"
		                else;                "unknown"
		                end
		self.data = file.read
		self.name = file.original_filename
		logger.info "self.id = #{self.id}"
	end
end

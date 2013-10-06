# Fedena
# Copyright 2011 Foradian Technologies Private Limited
#
# This product includes software developed at
# Project Fedena - http://www.projectfedena.org/
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
class ScheduledJobsController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  def index
    @jobs = Delayed::Job.all
    @all_jobs = @jobs.dup
    if params[:job_object] && params[:job_type]
      @jobs = []
      if params[:job_type]
        @job_type = params[:job_object].to_s + "/" + params[:job_type].to_s
        @all_jobs.each do|j|
          h = j.handler
          if h.present?
            obj = j.payload_object.class.name
            if j.payload_object.respond_to?("job_type")
              type = j.payload_object.job_type
              j_type = "#{obj}/#{type}"
              @jobs.push j if j_type == @job_type
            end
          end
        end
      else
        @job_type = params[:job_object].to_s
        @all_jobs.each do|j|
          h = j.handler
          if h.present?
            obj = j.payload_object.class.name
            @jobs.push j if obj == @job_type
          end
        end
      end
    end
  end
end

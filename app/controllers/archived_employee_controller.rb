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
class ArchivedEmployeeController < ApplicationController

  before_filter :login_required,:configuration_settings_for_hr
  filter_access_to :all
#  prawnto :prawn => {:left_margin => 25, :right_margin => 25}

  def profile
    @current_user = current_user
    @employee = ArchivedEmployee.find(params[:id])
    @new_reminder_count = Reminder.find_all_by_recipient_and_is_read(@current_user.id, false)
    #require 'debugger';debugger
    @gender = @employee.gender == 'f' ? 'Female' : 'Male'
    @status = @employee.status? ? 'Active' : 'Inactive'
    if @employee.reporting_manager_id.present?
      @reporting_manager = Employee.find_by_id(@employee.reporting_manager_id).try(:first_name) || ArchivedEmployee.find_by_id(@employee.reporting_manager_id).try(:first_name)
    end
    exp_years = @employee.experience_year
    exp_months = @employee.experience_month
    date = Date.today
    total_current_exp_days = (date - @employee.joining_date).to_i
    current_years = total_current_exp_days / 365
    rem = total_current_exp_days % 365
    current_months = rem / 30
    @total_years = exp_years + current_years if exp_years.present?
    @total_months = exp_months + current_months if exp_months.present?
  end

  def profile_general
    @employee = ArchivedEmployee.find(params[:id])
    @gender = @employee.gender == 'f' ? 'Female' : 'Male'
    @status = @employee.status? ? 'Active' : 'Inactive'
    @reporting_manager = ArchivedEmployee.find(@employee.reporting_manager_id).first_name if @employee.reporting_manager_id.present?
    exp_years = @employee.experience_year
    exp_months = @employee.experience_month
    date = Date.today
    total_current_exp_days = (date - @employee.joining_date).to_i
    current_years = total_current_exp_days / 365
    rem = total_current_exp_days % 365
    current_months = rem / 30
    @total_years = exp_years + current_years if exp_years.present?
    @total_months = exp_months + current_months if exp_months.present?
    render :partial => 'general'
  end

  def profile_personal
    @employee = ArchivedEmployee.find(params[:id])
    render :partial => 'personal'
  end

  def profile_address
    @employee = ArchivedEmployee.find(params[:id])
    @home_country = Country.find(@employee.home_country_id).name if @employee.home_country_id.present?
    @office_country = Country.find(@employee.office_country_id).name if @employee.office_country_id.present?
    render :partial => 'address'
  end

  def profile_contact
    @employee = ArchivedEmployee.find(params[:id])
    render :partial => 'contact'
  end

  def profile_bank_details
    @employee = ArchivedEmployee.find(params[:id])
    @bank_details = ArchivedEmployeeBankDetail.find_all_by_employee_id(@employee.id)
    render :partial => 'bank_details'
  end

  def profile_additional_details
    @employee = ArchivedEmployee.find(params[:id])
    @additional_details = ArchivedEmployeeAdditionalDetail.find_all_by_employee_id(@employee.id)
    render :partial => 'additional_details'
  end


  def profile_payroll_details
    @currency_type = Configuration.find_by_config_key('CurrencyType').config_value
    @employee = ArchivedEmployee.find(params[:id])
    @payroll_details = ArchivedEmployeeSalaryStructure.find_all_by_employee_id(@employee, :order=>'payroll_category_id ASC')
    render :partial => 'payroll_details'
  end

  def profile_pdf
    @employee = ArchivedEmployee.find(params[:id])
    @gender = @employee.gender == 'f' ? 'Female' : 'Male'
    @status = @employee.status? ? 'Active' : 'Inactive'
    @reporting_manager = ArchivedEmployee.find(@employee.reporting_manager_id).first_name if @employee.reporting_manager_id.present?
    exp_years = @employee.experience_year
    exp_months = @employee.experience_month
    date = Date.today
    total_current_exp_days = (date - @employee.joining_date).to_i
    current_years = total_current_exp_days / 365
    rem = total_current_exp_days % 365
    current_months = rem / 30
    @total_years = exp_years + current_years if exp_years.present?
    @total_months = exp_months + current_months if exp_months.present?
    @home_country = Country.find(@employee.home_country_id).name if @employee.home_country_id.present?
    @office_country = Country.find(@employee.office_country_id).name if @employee.office_country_id.present?
    @bank_details = ArchivedEmployeeBankDetail.find_all_by_employee_id(@employee.id)
    @additional_details = ArchivedEmployeeAdditionalDetail.find_all_by_employee_id(@employee.id)

    render :pdf => 'profile_pdf'
  end

  def show
    @employee = ArchivedEmployee.find(params[:id])
    send_data(@employee.photo_data, :type => @employee.photo_content_type, :filename => @employee.photo_filename, :disposition => 'inline')
  end


end

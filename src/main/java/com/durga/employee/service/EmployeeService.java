package com.durga.employee.service;

import com.durga.employee.dto.EmployeeRequest;

public interface EmployeeService {

	public void addEmployee(EmployeeRequest employeeRequest);
	public void updateEmployee(Long id, EmployeeRequest employeeRequest);
}

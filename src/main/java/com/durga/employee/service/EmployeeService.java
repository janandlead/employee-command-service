package com.durga.employee.service;

import com.durga.employee.dto.EmployeeRequest;
import com.durga.employee.dto.EmployeeResponse;
import com.durga.employee.entity.Employee;

public interface EmployeeService {

	public EmployeeResponse addEmployee(EmployeeRequest employeeRequest);
	public void updateEmployee(Long id, EmployeeRequest employeeRequest);
	public void deleteEmployee(Long id);
}

package com.durga.employee.controller;

import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.durga.employee.dto.EmployeeRequest;
import com.durga.employee.service.EmployeeService;

@RestController
@RequestMapping("/api/v1/employees")
public class EmployeeController {

	private final EmployeeService employeeService;

	public EmployeeController(EmployeeService employeeService) {
		this.employeeService = employeeService;
	}

	@PostMapping
	public void addEmployee(@RequestBody EmployeeRequest employeeRequest) {
		employeeService.addEmployee(employeeRequest);
	}

	// Want to update existing data in db

	@PutMapping("/{id}")
	public void addEmployee(@PathVariable Long id, @RequestBody EmployeeRequest employeeRequest) {
		employeeService.updateEmployee(id, employeeRequest);
	}
}

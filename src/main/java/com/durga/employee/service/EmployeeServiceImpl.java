package com.durga.employee.service;

import java.util.Optional;

import org.springframework.stereotype.Service;

import com.durga.employee.dto.EmployeeRequest;
import com.durga.employee.dto.EmployeeResponse;
import com.durga.employee.entity.Employee;
import com.durga.employee.repository.EmployeeRepository;

@Service
public class EmployeeServiceImpl implements EmployeeService {

	private final EmployeeRepository employeeRepository;

	public EmployeeServiceImpl(EmployeeRepository employeeRepository) {
		this.employeeRepository = employeeRepository;
	}

	@Override
	public EmployeeResponse addEmployee(EmployeeRequest employeeRequest) {

		Employee employee = new Employee();

		employee.setEmail(employeeRequest.getEmail());
		employee.setFirstName(employeeRequest.getFirstName());
		employee.setLastName(employeeRequest.getLastName());

		Employee employee2= employeeRepository.save(employee);
		return new EmployeeResponse(employee.getFirstName(), employee.getLastName(), employee.getEmail());

	}

	@Override
	public void updateEmployee(Long id, EmployeeRequest employeeRequest) {

		Employee employee = employeeRepository.findById(id)
				.orElseThrow(() -> new RuntimeException("Employee Not Found wiht id: " + id));

		employee.setEmail(employeeRequest.getEmail());
		employeeRepository.save(employee);

	}

	@Override
	public void deleteEmployee(Long id) {
		Employee employee = employeeRepository.findById(id)
				.orElseThrow(() -> new RuntimeException("Employee Not Found wiht id: " + id));

		employeeRepository.delete(employee);

	}

}

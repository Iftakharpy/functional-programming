alias KVS

defmodule Company do
  def get_employees() do
    KVS.get(:__employees__, %{})
  end

  def add_employee!(employee) when is_struct(employee, EmployeeStruct) do
    if get_employees() |> Map.has_key?(employee.id),
      do: raise("Employee with id #{employee.id} already exists")

    KVS.put(:__employees__, get_employees() |> Map.put(employee.id, employee))
  end

  def update_employee!(employee) when is_struct(employee, EmployeeStruct) do
    if not (KVS.get(:__employees__, %{}) |> Map.has_key?(employee.id)),
      do: raise("Employee with id #{employee.id} does not exist")

    KVS.put(:__employees__, get_employees() |> Map.put(employee.id, employee))
  end

  def remove_employee!(employee) when is_struct(employee, EmployeeStruct) do
    if not KVS.get(:__employees__, %{}) |> Map.has_key?(employee.id),
      do: raise("Employee with id #{employee.id} does not exist")

    KVS.put(:__employees__, get_employees() |> Map.delete(employee.id))
  end

  def get_employee_by_id(id) do
    get_employees() |> Map.get(id)
  end

  def get_employees_by_job(job) do
    get_employees() |> Enum.filter(fn e -> e.job == job end)
  end
end

alias KVS, as: KV_Storage
alias Employee, as: Employee
alias Company, as: Company

# Initialize the KV_Storage bucket
KV_Storage.start_link()

# Create employees
employee_1 = Employee.new("John", "Doe", :none)
employee_2 = Employee.new("Jane", "Doe", :none)

IO.puts("Create employees")
IO.inspect(employee_1)
IO.inspect(employee_2)
IO.puts("")

# promote employees
{:ok, employee_1} = Employee.promote(employee_1, :coder)
{:ok, employee_2} = Employee.promote(employee_2, :designer)

IO.puts("Promote employees")
IO.inspect(employee_1)
IO.inspect(employee_2)
IO.puts("")

# promote employees
{:ok, employee_1} = Employee.promote(employee_1, :manager)
{:ok, employee_2} = Employee.promote(employee_2, :ceo)

IO.puts("Promote employees")
IO.inspect(employee_1)
IO.inspect(employee_2)
IO.puts("")

# demote employees
{:ok, employee_1} = Employee.demote(employee_1, :designer)
{:ok, employee_2} = Employee.demote(employee_2, :manager)

IO.puts("Demote employees")
IO.inspect(employee_1)
IO.inspect(employee_2)
IO.puts("")

# demote employees
{:ok, employee_1} = Employee.demote(employee_1, :coder)
{:ok, employee_2} = Employee.demote(employee_2, :designer)

IO.puts("Demote employees")
IO.inspect(employee_1)
IO.inspect(employee_2)
IO.puts("")

# demote employees
{:ok, employee_1} = Employee.demote(employee_1, :none)
{:ok, employee_2} = Employee.demote(employee_2, :none)

IO.puts("Demote employees")
IO.inspect(employee_1)
IO.inspect(employee_2)
IO.puts("")

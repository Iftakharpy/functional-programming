alias KVS

defmodule EmployeeStruct do
  @enforce_keys [:id, :first_name, :last_name, :salary, :job]
  defstruct [:id, :first_name, :last_name, job: :none, salary: 0]
end

defmodule Employee do
  @jobs [:none, :coder, :designer, :manager, :ceo]
  def new(first_name, last_name, job)
      when is_bitstring(first_name) and
             is_bitstring(last_name) and
             job in @jobs do
    %EmployeeStruct{
      id: next_auto_id(),
      first_name: first_name,
      last_name: last_name,
      salary: get_salary_by_job(job),
      job: job
    }
  end

  def promote(employee, new_job)
      when new_job != employee.job do
    salary_change = get_salary_change_between_jobs(employee.job, new_job)

    cond do
      salary_change < 0 ->
        {:error,
         "Cannot promote #{employee.first_name} to a lower paying job. Should you be demoting #{employee.first_name} instead?"}

      salary_change > 0 ->
        {:ok, update_job(employee, new_job)}
    end
  end

  def demote(employee, new_job)
      when new_job != employee.job do
    salary_change = get_salary_change_between_jobs(employee.job, new_job)

    cond do
      salary_change > 0 ->
        {:error,
         "Cannot demote #{employee.first_name} to a higher paying job. Should you be promoting #{employee.first_name} instead?"}

      salary_change < 0 ->
        {:ok, update_job(employee, new_job)}
    end
  end

  def update_job(employee, new_job)
      when is_struct(employee, EmployeeStruct) do
    %EmployeeStruct{
      employee
      | salary: employee.salary + get_salary_change_between_jobs(employee.job, new_job),
        job: new_job
    }
  end

  def get_salary_change_between_jobs(prev_job, new_job) do
    get_salary_by_job(new_job) - get_salary_by_job(prev_job)
  end

  @base_salary 0
  @salary_increment 2000
  def get_salary_by_job(job) when job in @jobs do
    salary_increment_for_job =
      @salary_increment *
        (Stream.with_index(@jobs) |> Enum.find(fn {job_i, _} -> job_i == job end) |> elem(1))

    @base_salary + salary_increment_for_job
  end

  @auto_id_start 0
  def next_auto_id() do
    # get the current auto_id
    auto_id =
      KVS.get(:__auto_id__)
      |> case do
        nil -> @auto_id_start
        id -> id
      end

    # increment the auto_id
    KVS.put(:__auto_id__, auto_id + 1)

    auto_id
  end
end

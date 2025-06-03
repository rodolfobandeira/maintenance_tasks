# frozen_string_literal: true

require "test_helper"

module MaintenanceTasks
  class TaskDataIndexTest < ActiveSupport::TestCase
    test ".available_tasks returns a list of Tasks as TaskDataShow, ordered alphabetically by name" do
      expected = [
        "Maintenance::BatchImportPostsTask",
        "Maintenance::CallbackTestTask",
        "Maintenance::CancelledEnqueueTask",
        "Maintenance::CustomEnumeratingTask",
        "Maintenance::EnqueueErrorTask",
        "Maintenance::ErrorTask",
        "Maintenance::ImportPostsTask",
        "Maintenance::ImportPostsWithEncodingTask",
        "Maintenance::ImportPostsWithOptionsTask",
        "Maintenance::Nested::NestedMore::NestedMoreTask",
        "Maintenance::Nested::NestedTask",
        "Maintenance::NoCollectionTask",
        # duplicate due to fixtures containing two active runs of this task
        "Maintenance::NoCollectionTask",
        "Maintenance::ParamsTask",
        "Maintenance::TestTask",
        "Maintenance::UpdatePostsInBatchesTask",
        "Maintenance::UpdatePostsModulePrependedTask",
        "Maintenance::UpdatePostsTask",
        "Maintenance::UpdatePostsThrottledTask",
      ]
      assert_equal expected, TaskDataIndex.available_tasks.map(&:name)
    end

    test ".available_tasks assigns related run by most recent created completed run" do
      tasks = TaskDataIndex.available_tasks
      task = tasks.find { |task| task.name == "Maintenance::ImportPostsTask" }

      assert_equal maintenance_tasks_runs(:import_posts_task_succeeded), task.related_run
    end

    test "#new sets last_run if one is passed as an argument" do
      run = Run.create!(task_name: "Maintenance::UpdatePostsTask")
      task_data = TaskDataIndex.new("Maintenance::UpdatePostsTask", run)

      assert_equal "Maintenance::UpdatePostsTask", task_data.to_s
    end

    test "#to_s returns the name of the Task" do
      task_data = TaskDataIndex.new("Maintenance::UpdatePostsTask")

      assert_equal "Maintenance::UpdatePostsTask", task_data.to_s
    end

    test "#status is new when Task does not have any Runs" do
      task_data = TaskDataIndex.new("Maintenance::UpdatePostsTask")
      assert_equal "new", task_data.status
    end

    test "#status is the latest Run status" do
      run = Run.create!(
        task_name: "Maintenance::UpdatePostsTask",
        status: :paused,
      )
      task_data = TaskDataIndex.new("Maintenance::UpdatePostsTask", run)
      assert_equal "paused", task_data.status
    end

    test "#category returns :active if the task is active" do
      run = Run.create!(task_name: "Maintenance::UpdatePostsTask")
      task_data = TaskDataIndex.new("Maintenance::UpdatePostsTask", run)
      assert_equal :active, task_data.category
    end

    test "#category returns :new if the task is new" do
      assert_equal :new, TaskDataIndex.new("Maintenance::SomeNewTask").category
    end

    test "#category returns :completed if the task is completed" do
      run = Run.create!(
        task_name: "Maintenance::UpdatePostsTask",
        status: :succeeded,
      )
      task_data = TaskDataIndex.new("Maintenance::UpdatePostsTask", run)
      assert_equal :completed, task_data.category
    end

    test ".search returns tasks matching the search query" do
      tasks = TaskDataIndex.available_tasks
      search_results = TaskDataIndex.search(tasks, "UpdatePosts")

      expected = [
        "Maintenance::UpdatePostsInBatchesTask",
        "Maintenance::UpdatePostsModulePrependedTask",
        "Maintenance::UpdatePostsTask",
        "Maintenance::UpdatePostsThrottledTask",
      ]
      assert_equal expected, search_results.map(&:name)
    end

    test ".search returns empty array when no tasks match the query" do
      tasks = TaskDataIndex.available_tasks
      search_results = TaskDataIndex.search(tasks, "NonExistentTask")
      assert_empty search_results
    end

    test ".search is case insensitive" do
      tasks = TaskDataIndex.available_tasks
      search_results = TaskDataIndex.search(tasks, "updateposts")

      expected = [
        "Maintenance::UpdatePostsInBatchesTask",
        "Maintenance::UpdatePostsModulePrependedTask",
        "Maintenance::UpdatePostsTask",
        "Maintenance::UpdatePostsThrottledTask",
      ]
      assert_equal expected, search_results.map(&:name)
    end

    test ".search matches partial task names" do
      tasks = TaskDataIndex.available_tasks
      search_results = TaskDataIndex.search(tasks, "Update")

      expected = [
        "Maintenance::UpdatePostsInBatchesTask",
        "Maintenance::UpdatePostsModulePrependedTask",
        "Maintenance::UpdatePostsTask",
        "Maintenance::UpdatePostsThrottledTask",
      ]
      assert_equal expected, search_results.map(&:name)
    end
  end
end

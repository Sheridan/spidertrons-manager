if storage.spidertron_manager_data then
  if storage.spidertron_manager_data.selection_target then
    storage.spidertron_manager_data.selection_target_group = storage.spidertron_manager_data.selection_target
    storage.spidertron_manager_data.selection_target = nil
  end
  if not storage.spidertron_manager_data.settings_source_spidertron then
    storage.spidertron_manager_data.settings_source_spidertron = nil
  end
end

module ApplicationHelper
  def new_form_item(builder, relation, template)
    obj = builder.object.send(relation).build
    builder.fields_for(relation, obj, child_index: '$') { |b| render(template, f: b).gsub("\n", '') }
  end

  def link_to_destroy(path)
    icon = content_tag(:span, nil, class: 'glyphicon glyphicon-remove')
    link_to icon, path, method: :delete, data: { confirm: 'Tem certeza?' }
  end

  def zero_filed_zip(zip)
     zip.present? ? sprintf('%08d', zip.to_s.gsub(/\D/, '').to_i) : ""
  end
end

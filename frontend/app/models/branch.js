import DS from 'ember-data';

export default DS.Model.extend({
  name: DS.attr('string'),
  project: DS.belongsTo('project'),
  builds: DS.hasMany('build')
});

import DS from 'ember-data';

export default DS.JSONAPIAdapter.extend({
  host: 'http://' + document.location.hostname + ':4000'
});

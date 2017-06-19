/*
* During course of a puppet apply, how many objects do we create, of what kind?
*
* See
* https://github.com/ruby/ruby/blob/6bc742bc6d0dc6b1777d28484f4694af846bfb79/spec/rubyspec/optional/capi/object_spec.rb#L61-L67
* https://github.com/ruby/ruby/blob/d0015e4ac6b812ea1681b1f5fa86fbab52a58960/object.c#L1939-L1943
*
* Call example:
* given puppet manifest:
*
* $ cat ~/notify.pp
notify { 'foo' : }
*
* sudo dtrace -s ruby-objects-created.d -c '/Users/foo/.rbenv/versions/2.3.1/bin/bundle exec puppet apply /Users/foo/notify.pp
*
* Note that call invokes via bundler which includes additional overhead
*/

ruby*:::object-create
{
  /*
    - `self->` denotes a thread-local variable, see
      http://dtrace.org/guide/chp-variables.html#chp-variables-3
    - `arg0` is the first argument passed to the function, in our case the class name
    - `@` denotes that @created_objects is an aggregation object, see
      http://dtrace.org/guide/chp-aggs.html
    - `copyinstr` reads string at address of arg0, see
      http://dtrace.org/guide/chp-user.html#chp-user-1
  */
  self->object_classname = arg0;
  @created_objects[copyinstr(self->object_classname)] = count();
}

END {
  /*
    - `printa` is the print function for an aggregation objects, see
      http://dtrace.org/guide/chp-fmt.html#chp-fmt-printa
  */
  printa(@created_objects);
}

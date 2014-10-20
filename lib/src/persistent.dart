// Copyright (c) 2014, VacuumLabs.
// Copyright (c) 2012, Google Inc. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// Authors are listed in the AUTHORS file

part of persistent;

/**
 * All the persistent structures implements this.
 */
class PersistentCollection {}

class _Owner {}

/**
 * Converts structure of [List]s and [Map]s to the equivalent
 * persistent structure.
 *
 * Works recursively.
 */
persist(from) {
  if(from is PersistentCollection) return from;
  if(from is Map) {
    var map = new PersistentMap();
    return map.withTransient((TransientMap map) {
      from.forEach((key,value) => map.doAssoc(per(key), per(value)));
    });
  }
  else if (from is Set) {
    from = from.map((e) => persist(e));
    return new PersistentSet.from(from);
  }
  else if(from is Iterable) {
    from = from.map((e) => persist(e));
    return new PersistentVector.from(from);
  }
  else {
    return from;
  }
}

/// Alias for [persist]
per(from) => persist(from);

class None{
  const None();
}

const _none = const None();
final _getNone = () => _none;
bool _isNone(val) => val == _none;

/**
 * Looks up the element given by the [path] of keys and indices
 * in the [structure] of Maps and Vectors.
 *
 * If the [path] does not exist, [orElse] is called to obtain the
 * return value. Default [orElse] throws exception.
 */
lookupIn(PersistentCollection structure, List path, {notFound}) =>
    _lookupIn(structure, path.iterator, notFound: notFound);

_lookupIn(dynamic s, Iterator path, {notFound}) {
  if(!path.moveNext()) return s;
  if(s is PersistentMap) {
    return _lookupIn(s.get(path.current, notFound), path, notFound: notFound);
  }
  else if(s is PersistentVector) {
    return _lookupIn(s.get(path.current, notFound), path, notFound: notFound);
  }
  else if(s is TransientMap) {
    return _lookupIn(s.get(path.current, notFound), path, notFound: notFound);
  }
  else if(s is TransientVector) {
    return _lookupIn(s.get(path.current, notFound), path, notFound: notFound);
  }
  else {
    throw new Exception('This should not happen');
  }
}

/**
 * Inserts the [value] to the position given by the [path] of keys and indices
 * in the [structure] of Maps and Vectors.
 *
 * This will not create any middleway structures.
 */
PersistentCollection insertIn(PersistentCollection structure, Iterable path, dynamic value) =>
    _insertIn(structure, path.iterator..moveNext(), value);

PersistentCollection _insertIn(s, Iterator path, dynamic value) {
  var current = path.current;
  if(path.moveNext()) { //path continues
    if(s is PersistentMap) {
      return s.assoc(current, _insertIn(s.get(current), path, value));
    }
    else if(s is PersistentVector) {
      return s.set(current, _insertIn(s.get(current), path, value));
    }
    else if(s is TransientMap) {
      return s.doAssoc(current, _insertIn(s.get(current), path, value));
    }
    else if(s is TransientVector) {
      return s.doSet(current, _insertIn(s.get(current), path, value));
    }
    else {
      throw new Exception('This should not happen');
    }
  }
  else {
    if(s is PersistentMap) {
      return s.assoc(current, value);
    }
    else if(s is PersistentVector) {
      if(current == s.length) {
        return s.push(value);
      }
      return s.set(current, value);
    }
    else if(s is TransientMap) {
      return s.doAssoc(current, value);
    }
    else if(s is TransientVector) {
      if(current == s.length) {
        return s.doPush(value);
      }
      return s.doSet(current, value);
    }
    else {
      throw new Exception('This should not happen');
    }
  }
}

/**
 * Removes the element given by the [path] of keys and indices
 * in the [structure] of Maps and Vectors.
 *
 * If the [path] does not exist and [safe] is not `true`, exception is thrown.
 * If the [path] does not exist and [safe] is specified as `true`,
 * the same map is returned.
 */
PersistentCollection deleteIn(PersistentCollection structure, List path, {bool safe: false}) =>
    _deleteIn(structure, path.iterator..moveNext(), safe: safe);

PersistentCollection _deleteIn(s, Iterator path, {bool safe: false}) {
  var current = path.current;
  if(path.moveNext()) { //path continues
    if(s is PersistentMap) {
      var deleted = _deleteIn(s.get(current), path, safe: safe);
      return s.assoc(current, deleted);
    }
    else if(s is PersistentVector) {
      var deleted = _deleteIn(s.get(current), path, safe: safe);
      return s.set(current, deleted);
    }
    else if(s is TransientMap) {
      var deleted = _deleteIn(s.get(current), path, safe: safe);
      return s.doAssoc(current, deleted);
    }
    else if(s is TransientVector) {
      var deleted = _deleteIn(s.get(current), path, safe: safe);
      return s.doSet(current, deleted);  }
    else {
      throw new Exception('This should not happen');
    }
  }
  else {
    if(s is PersistentMap) {
      return s.delete(current);
    }
    else if(s is PersistentVector) {
      if(s.length - 1 == current) return s.pop();
      else throw new Exception('Cannot delete non last element in PersistentVector');
    }
    else if(s is TransientMap) {
      return s.doDelete(current);
    }
    else if(s is TransientVector) {
      if(s.length - 1 == current) return s.doPop();
      else throw new Exception('Cannot delete non last element in TransientVector');
    }
    else {
      throw new Exception('This should not happen');
    }
  }
  return throw 'It cant get here...';
}

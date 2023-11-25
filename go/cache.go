package main

import "sync"

type cache[K comparable, V any] struct {
	sync.RWMutex
	items map[K]V
}

func NewCache[K comparable, V any]() *cache[K, V] {
	m := make(map[K]V)
	c := &cache[K, V]{
		items: m,
	}
	return c
}

func (c *cache[K, V]) Set(key K, value V) {
	c.Lock()
	c.items[key] = value
	c.Unlock()
}

func (c *cache[K, V]) Get(key K) (V, bool) {
	c.RLock()
	v, found := c.items[key]
	c.RUnlock()
	return v, found
}

func (c *cache[K, V]) Init() {
	c.Lock()
	c.items = make(map[K]V)
	c.Unlock()
}

func (c *cache[K, V]) Delete(key K) {
	c.Lock()
	delete(c.items, key)
	c.Unlock()
}

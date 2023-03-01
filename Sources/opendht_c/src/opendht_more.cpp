//
//  opendht_more.c
//  
//
//  Created by Eugene Antropov on 21.02.2023.
//

#include "opendht_c.h"
#include "opendht_more.h"

#include <opendht.h>
#include <opendht/log.h>

using ValueSp = std::shared_ptr<dht::Value>;
using ValueTypeSp = std::shared_ptr<dht::ValueType>;

#ifdef __cplusplus
extern "C" {
#endif

#include <errno.h>

inline dht_infohash dht_infohash_to_c(const dht::InfoHash& h) {
    dht_infohash ret;
    *reinterpret_cast<dht::InfoHash*>(&ret) = h;
    return ret;
}

void dht_runner_get_with_filter(dht_runner* r, const dht_infohash* h, dht_get_cb cb, dht_done_cb done_cb, void* cb_user_data, dht_filter_cb filter_cb) {
    auto runner = reinterpret_cast<dht::DhtRunner*>(r);
    auto hash = reinterpret_cast<const dht::InfoHash*>(h);
    auto filter = reinterpret_cast<const dht::Value::Filter*>(h);
    runner->get(*hash, [cb,cb_user_data](std::shared_ptr<dht::Value> value){
        return cb(reinterpret_cast<const dht_value*>(&value), cb_user_data);
    }, [done_cb, cb_user_data](bool ok){
        if (done_cb)
            done_cb(ok, cb_user_data);
    }, [filter_cb, cb_user_data](const dht::Value& value){
        auto myValue = &value;
        return filter_cb(reinterpret_cast<dht_value *>(&myValue), cb_user_data);
    });
}


void dht_value_set_id(dht_value* data, dht_value_id id) {
    (*reinterpret_cast<ValueSp*>(data))->id = id;
}

dht_value_type* dht_value_type_default_userdata() {
    dht::ValueType val = dht::ValueType::USER_DATA;
    std::shared_ptr<dht::ValueType> valueType(&val);
    return reinterpret_cast<dht_value_type*>(new ValueTypeSp(valueType));
}

dht_value* dht_value_new_with_type(const uint8_t* data, size_t size, uint16_t type) {
    return reinterpret_cast<dht_value*>(new ValueSp(std::make_shared<dht::Value>(type, data, size)));
}

uint16_t dht_value_get_valuetype_id(const dht_value* data) {
    const ValueSp& vsp(*reinterpret_cast<const ValueSp*>(data));
    return vsp->type;
}

uint16_t dht_get_valuetype_id(const dht_value_type* t) {
    const ValueTypeSp& vts(*reinterpret_cast<const ValueTypeSp*>(t));
    return vts->id;
}

const char* dht_get_valuetype_name(const dht_value_type* t) {
    const ValueTypeSp& vts(*reinterpret_cast<const ValueTypeSp*>(t));
    return vts->name.c_str();
}

void dht_register_value_type(dht_runner* r, dht_value_type* t) {
    auto runner = reinterpret_cast<dht::DhtRunner*>(r);
    ValueTypeSp& vts(*reinterpret_cast<ValueTypeSp*>(t));
    dht::ValueType type = *vts;
    runner->registerType(type);
}

dht_value_type* dht_valuetype_new(uint16_t id, const char* name, uint32_t duration, dht_store_policy sp, dht_edit_policy ep, void* cb_user_data) {
    auto value_type = reinterpret_cast<dht_value_type*>(new ValueTypeSp(std::make_shared<dht::ValueType>(
                                              id,
                                              name,
                                              std::chrono::seconds(duration),
                                              [cb_user_data, sp](dht::InfoHash k, std::shared_ptr<dht::Value>& value, const dht::InfoHash& from, const dht::SockAddr& addr){
                                                  dht_infohash key;
                                                  *reinterpret_cast<dht::InfoHash*>(&key) = k;
                                                  return sp(
                                                            key,
                                                            reinterpret_cast<const dht_value*>(&value),
                                                            dht_infohash_to_c(from),
                                                            addr.get(),
                                                            addr.getLength(),
                                                            cb_user_data
                                                            );
                                              },
                                              [cb_user_data, ep](dht::InfoHash k, const std::shared_ptr<dht::Value>& old_val, std::shared_ptr<dht::Value>& new_val, const dht::InfoHash& from, const dht::SockAddr& addr) {
                                                  dht_infohash key;
                                                  *reinterpret_cast<dht::InfoHash*>(&key) = k;
                                                  return ep(
                                                            key,
                                                            reinterpret_cast<const dht_value*>(&old_val),
                                                            reinterpret_cast<const dht_value*>(&new_val),
                                                            dht_infohash_to_c(from),
                                                            (struct sockaddr *) addr.get(),
                                                            addr.getLength(),
                                                            cb_user_data
                                                            );
                                              })));
    return value_type;
}
#ifdef __cplusplus
}
#endif

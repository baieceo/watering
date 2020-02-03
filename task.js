(function () {
	// let host = 'http://192.168.31.68';
	let host = '';
	let querystring = {};

	querystring.parse = function (str) {
		let obj = {};

		str.split('&').forEach(item => {
			let o = item.split('=');

			obj[o[0]] = o[1];
		});

		return obj;
	}

	querystring.stringify = function (data) {
		let result = [];

		for (let k in data) {
			result.push(`${k}=${data[k]}`);
		}

		return result.join('&');
	}

	// 定义 Toast 组件
	const Toast = new Vue({
		el: '#toast',
		data () {
			return {
				canShow: false,
				timer: null,
				defaultDuration: 3000,
				content: ''
			}
		},
		methods: {
			show (content, duration, onClose) {
				if (this.canShow) {
					this.hide();
				}

				this.content = content;
				this.canShow = true;

				this.timer = setTimeout(() => {
					this.hide();

					onClose && onClose();
				}, duration || this.defaultDuration);
			},
			hide () {
				if (this.timer) {
					clearTimeout(this.timer);

					this.timer = null;
				}

				this.canShow = false;
			},
			// Toast.success(content, duration, onClose, mask)
			success (content, duration, onClose, mask) {
				this.show(content, duration, onClose, mask);
			},
			// Toast.fail(content, duration, onClose, mask)
			fail (content, duration, onClose, mask) {
				this.show(content, duration, onClose, mask);
			},
			// Toast.info(content, duration, onClose, mask)
			info (content, duration, onClose, mask) {
				this.show(content, duration, onClose, mask);
			}
		}
	});

	// 定义 Modal 组建
	const Modal = new Vue({
		el: '#modal',
		data () {
			return {
				canShow: false,
				title: 'title',
				message: 'message',
				buttonGroups: []
			}
		},
		methods: {
			// alert(title, message, [{text, onPress, style}]
			alert (title, message, buttonGroups) {
				this.title = title;
				this.message = message;
				this.buttonGroups = buttonGroups;
				this.canShow = true;
			},
			close () {
				this.canShow = false;
				this.title = '';
				this.message = '';
				this.buttonGroups = [];
			}
		}
	});
	
	let app = new Vue({
		el: '#app',
		data () {
			return {
				taskListLoaded: false,
				tasks: [],
				deviceTimeStamp: 0,
				deviceTimer: null
			}
		},
		created () {
			this.queryTaskList().then(this.fetchRtctime).then(this.startTimeCount);
		},
		computed: {
			timeStamp () {
				let offsetUtc = 8 * 60;

				return moment(this.deviceTimeStamp).utc(offsetUtc).format('YYYY-MM-DD HH:mm:ss');
			}
		},
		methods: {
			startTimeCount () {
				let count = 0;
				let lastTime = 0;

				if (this.deviceTimer) clearInterval(this.deviceTimer);

				this.deviceTimer = setInterval(() => {
					this.deviceTimeStamp += 1000;

					count++;

					if (count > 60) {
						this.fetchRtctime();

						count = 0;
					}

					lastTime = +new Date();
				}, 1000);
			},
			fetchRtctime () {
				return fetch(`${host}/rtctime`).then(res => res.text()).then(rtc => {
					this.deviceTimeStamp = Number(rtc) * 1000;
				});
			},
			queryTaskList (callback) {
				return fetch(`${host}/task/query`).then(res => res.text()).then(res => {
					let tasks = res.split('\n').filter(item => item.length).map(item => querystring.parse(item));

					tasks.forEach(item => {
						let schedule = item.schedule.split(' ');

						item.status = 'normal';

						let hour = Number(schedule[1]);

						if (hour > 15) item.hour = hour - 16;
						else item.hour = hour + 8;

						item.minute = schedule[0];
						item.day = schedule[2];
						item.duration = Number(item.duration) / 1000;
						item.open = !!item.open;
					});

					this.tasks = tasks;
					this.taskListLoaded = true;
				});
			},
			updateTask (id, item) {
				item.id = id;

				let data = this.getSaveItem(item);
				let body = querystring.stringify(data);

				return fetch(`${host}/task/update?${body}`).then(res => res.json()).then(res => {
					if (res.success) {
						Toast.success('保存成功');
					} else {
						Toast.fail('保存失败');
					}
				}, rej => {
					Toast.fail('保存失败');
				});
			},
			removeTask (index) {
				return fetch(`${host}/task/remove?id=${index}`).then(res => res.json()).then(res => {
					if (res.success) {
						Toast.success('删除成功');
					} else {
						Toast.fail('删除失败');
					}

					this.tasks.splice(index, 1);

					Modal.close();
				}, rej => {
					Toast.fail('删除失败');
				});
			},
			addTask (item) {
				let data = this.getSaveItem(item);

				let body = querystring.stringify(data);

				return fetch(`${host}/task/add?${body}`).then(res => res.json()).then(res => {
					if (res.success) {
						Toast.success('保存成功');
					} else {
						Toast.fail('保存失败');
					}

					item.status = 'normal';
				}, rej => {
					Toast.fail('保存失败');
				});
			},
			deviceRestart () {
				Modal.alert('提示', `是否重启设备？`, [
					{ 
						text: '取消', 
						onPress: () => {
							Modal.close();
						}
					},
					{ 
						text: '确定', 
						onPress: () => {
							fetch(`${host}/restart`).then(res => res.json()).then(res => {
								if (res.success) {
									Toast.success('重启成功');
								} else {
									Toast.fail('重启失败');
								}

								Modal.close();
							}, rej => {
								Toast.fail('重启失败');
							});
						}
					}
				]);
			},
			startTask () {
				return fetch(`${host}/task/start`).then(res => res.json()).then(res => {
					if (res.success) {
						Toast.success('开启成功');
					} else {
						Toast.fail('开启失败');
					}
				}, rej => {
					Toast.fail('开启失败');
				});
			},
			stopTask () {
				return fetch(`${host}/task/stop`).then(res => res.json()).then(res => {
					if (res.success) {
						Toast.success('停止成功');
					} else {
						Toast.fail('停止失败');
					}
				}, rej => {
					Toast.fail('停止失败');
				});
			},
			getSaveItem (item) {
				let data = Object.assign({}, item);

				data.duration = Number(item.duration) * 1000;

				if (data.hour < 8) {
					data.hour = data.hour + 16;
				} else {
					data.hour = data.hour - 8;
				}

				data.open = !!data.open;

				if (!data.open) delete data.open;

				data.schedule = [data.minute, data.hour, data.day, '*', '*'].join(' ');

				delete data.day;
				delete data.hour;
				delete data.minute;
				delete data.status;

				return data;
			},
			createTaskItem () {
				return {
					status: 'add',
					hour: 0,
					minute: 0,
					day: '*/1',
					duration: 0,
					open: false,
					pin: 0
				};
			},
			handleTaskEdit (index) {
				this.tasks[index].status = 'edit';
			},
			handleTaskSave (index) {
				this.tasks[index].status = 'normal';

				this.updateTask(index, this.tasks[index]);
			},
			handleTaskRemove (index) {
				Modal.alert('提示', `确定删除 任务 ${ index + 1 }？`, [
					{ 
						text: '取消', 
						onPress: () => {
							Modal.close();
						}
					},
					{ 
						text: '确定', 
						onPress: () => {
							this.removeTask(index);
						}
					}
				]);
			},
			handleTaskAdd () {
				this.tasks.push(this.createTaskItem());
			},
			handleTaskAddSave (item) {
				this.addTask(item);
			},
			handleTaskAddCancel () {
				this.tasks.pop();
			}
		}
	});
})();
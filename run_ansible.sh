#!/bin/sh
ansible-playbook -v --extra-vars "taskname=copy_ssh" ansible/playbook.yml
ansible-playbook -v --extra-vars "taskname=ros" ansible/playbook.yml
ansible-playbook -v --extra-vars "taskname=finish_messages" ansible/playbook.yml
